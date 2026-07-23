import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audioplayers/audioplayers.dart' as legacy_audio;
import 'package:audio_session/audio_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// A singleton manager to handle voice message playback across the app.
/// This ensures only one voice message plays at a time and maintains state during scrolling.
class VoicePlaybackManager extends ChangeNotifier {
  static final VoicePlaybackManager _instance =
      VoicePlaybackManager._internal();
  factory VoicePlaybackManager() => _instance;

  VoicePlaybackManager._internal() {
    _player = just_audio.AudioPlayer();
    _legacyPlayer = _createLegacyPlayer();
    _initAudioSession();

    _player.playerStateStream.listen((state) {
      if (state.processingState == just_audio.ProcessingState.completed) {
        _stopInternal(clearCurrent: true, resetPosition: true);
      }
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      final bool buffering =
          state == just_audio.ProcessingState.buffering ||
          state == just_audio.ProcessingState.loading;
      if (_isBuffering != buffering) {
        _isBuffering = buffering;
        notifyListeners();
      }
    });

    _player.durationStream.listen((duration) {
      if (duration != null && duration.inSeconds > 0) {
        if (_currentAudioUrl != null) {
          _durationCache[_currentAudioUrl!] = duration.inSeconds;
        }
        if (_currentAudioMessageId != null) {
          _durationCacheByMessageId[_currentAudioMessageId!] =
              duration.inSeconds;
        }
        notifyListeners();
      }
    });

    _legacyPlayer.onPlayerComplete.listen((_) {
      _usingLegacyPlayback = false;
      _currentAudioUrl = null;
      notifyListeners();
    });

    // 🛡️ PERFORMANCE: Do NOT call notifyListeners() on every position update.
    // This was causing massive jank as all bubbles were rebuilding.
    // _player.positionStream.listen((_) => notifyListeners());
    // _player.durationStream.listen((_) => notifyListeners());
  }

  late final just_audio.AudioPlayer _player;
  late legacy_audio.AudioPlayer _legacyPlayer;
  String? _currentAudioUrl;
  String? _currentAudioMessageId;
  bool _usingLegacyPlayback = false;
  Duration? _legacyDuration;
  double _currentSpeed = 1.0;
  bool _isBuffering = false;
  int _playbackRequestId = 0;

  final Set<String> _preloadingUrls = {};
  final Map<String, int> _durationCache = {};
  final Map<String, int> _durationCacheByMessageId = {};
  final SecureStorageService _storageService = SecureStorageService();

  just_audio.AudioPlayer get player => _player;
  String? get currentAudioUrl => _currentAudioUrl;
  String? get currentAudioMessageId => _currentAudioMessageId;
  int? getCachedDuration(String url) => _durationCache[url];
  int? getCachedDurationByMessageId(String messageId) =>
      _durationCacheByMessageId[messageId];
  bool get isPlaying => _usingLegacyPlayback
      ? _legacyPlayer.state == legacy_audio.PlayerState.playing
      : _player.playing;
  bool get isBuffering => _isBuffering;
  double get currentSpeed => _currentSpeed;

  // 🚀 Added streams for granular UI updates
  Stream<Duration> get positionStream => _usingLegacyPlayback
      ? _legacyPlayer.onPositionChanged
      : _player.positionStream;
  Stream<Duration?> get durationStream => _usingLegacyPlayback
      ? _legacyPlayer.onDurationChanged
      : _player.durationStream;
  Duration? get currentDuration =>
      _usingLegacyPlayback ? _legacyDuration : _player.duration;

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        ),
      );
      // Activate the session immediately so iOS registers the app as an audio
      // player. Without this, the first playback attempt on iOS can fail silently
      // or produce no sound because the system hasn't allocated the audio route.
      await session.setActive(true);
      debugPrint('✅ [VOICE] AudioSession initialized and activated');
    } catch (e) {
      debugPrint('⚠️ [VOICE] AudioSession init error (non-fatal): $e');
      // Non-fatal — playback will still be attempted; togglePlay re-activates.
    }
  }

  legacy_audio.AudioPlayer _createLegacyPlayer() {
    final player = legacy_audio.AudioPlayer();
    player.setReleaseMode(legacy_audio.ReleaseMode.stop);
    player.onPlayerComplete.listen((_) {
      _usingLegacyPlayback = false;
      _currentAudioUrl = null;
      _currentAudioMessageId = null;
      notifyListeners();
    });
    player.onPlayerStateChanged.listen((state) {
      _usingLegacyPlayback = true;
      if (state == legacy_audio.PlayerState.completed) {
        _currentAudioUrl = null;
        _currentAudioMessageId = null;
      }
      if (state == legacy_audio.PlayerState.playing) {
        player.setPlaybackRate(_currentSpeed).catchError((_) {});
      }
      notifyListeners();
    });
    player.onDurationChanged.listen((duration) {
      _legacyDuration = duration;
      if (duration.inSeconds > 0) {
        if (_currentAudioUrl != null) {
          _durationCache[_currentAudioUrl!] = duration.inSeconds;
        }
        if (_currentAudioMessageId != null) {
          _durationCacheByMessageId[_currentAudioMessageId!] =
              duration.inSeconds;
        }
        notifyListeners();
      }
    });
    return player;
  }

  Future<void> _disposeLegacyPlayer() async {
    try {
      await _legacyPlayer.stop();
    } catch (_) {}
    try {
      await _legacyPlayer.release();
    } catch (_) {}
    try {
      await _legacyPlayer.dispose();
    } catch (_) {}
    _legacyDuration = null;
  }

  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    if (_usingLegacyPlayback) {
      try {
        await _legacyPlayer.setPlaybackRate(speed);
      } catch (_) {}
    } else {
      try {
        await _player.setSpeed(speed);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> toggleSpeed() async {
    if (_currentSpeed == 1.0) {
      await setSpeed(1.5);
    } else if (_currentSpeed == 1.5) {
      await setSpeed(2.0);
    } else {
      await setSpeed(1.0);
    }
  }

  /// Checks if a file is already cached and returns its local path
  Future<String?> getCachedPath(String url) async {
    if (!url.startsWith('http')) return url;
    try {
      final dir = await getTemporaryDirectory();
      final filename = _getFilenameFromUrl(url);
      final filePath = '${dir.path}/voice_cache_$filename';
      if (await File(filePath).exists()) {
        return filePath;
      }
    } catch (e) {
      debugPrint('⚠️ [VOICE] Cache check error: $e');
    }
    return null;
  }

  String _getFilenameFromUrl(String url) {
    // Use a stable hash of the full URL so different media cannot collide even
    // if they share the same basename or lack query parameters.
    final uri = Uri.parse(url);
    final lastPart = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'voice';
    final safeName = lastPart.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final urlHash = _stableUrlHash(url);
    return '${safeName}_$urlHash';
  }

  String _stableUrlHash(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Preloads audio by downloading it to local cache
  Future<void> preload(String url) async {
    if (!url.startsWith('http') || _preloadingUrls.contains(url)) return;

    final cachedPath = await getCachedPath(url);
    if (cachedPath != null) return;

    _preloadingUrls.add(url);
    debugPrint('📥 [VOICE] Preloading: $url');

    try {
      await _downloadAndCache(url);
    } catch (e) {
      debugPrint('⚠️ [VOICE] Preload failed for $url: $e');
    } finally {
      _preloadingUrls.remove(url);
    }
  }

  String _normalizeLocalPath(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('file://')) {
      return Uri.parse(trimmed).toFilePath();
    }
    return trimmed;
  }

  /// Downloads [url] to local cache and returns (filePath, contentType).
  Future<(String, String?)> _downloadAndCacheWithMime(String url) async {
    final dir = await getTemporaryDirectory();
    final filename = _getFilenameFromUrl(url);
    final filePath = '${dir.path}/voice_cache_$filename';

    if (await File(filePath).exists()) {
      // File already cached — content-type unavailable without re-fetching headers.
      // Rely on URL extension check for already-cached files.
      return (filePath, null);
    }

    try {
      final token = await _storageService.getToken();
      final session = await _storageService.getSession();
      final dio = Dio();
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      if (session != null && session.isNotEmpty) {
        dio.options.headers['Cookie'] = session;
      }
      dio.options.headers['Accept'] = '*/*';
      dio.options.headers['X-Requested-With'] = 'XMLHttpRequest';

      String? contentType;
      final response = await dio.download(
        url,
        filePath,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
        onReceiveProgress: (sent, total) {},
      );
      contentType = response.headers.value(Headers.contentTypeHeader);
      debugPrint(
        '📡 [VOICE] Downloaded: status=${response.statusCode}, mime=$contentType, path=$filePath',
      );
      return (filePath, contentType);
    } catch (e) {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<String> _downloadAndCache(String url) async {
    final dir = await getTemporaryDirectory();
    final filename = _getFilenameFromUrl(url);
    final filePath = '${dir.path}/voice_cache_$filename';

    // Check again to avoid duplicate downloads
    if (await File(filePath).exists()) return filePath;

    try {
      final token = await _storageService.getToken();
      final session = await _storageService.getSession();
      final dio = Dio();
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      if (session != null && session.isNotEmpty) {
        dio.options.headers['Cookie'] = session;
      }
      dio.options.headers['Accept'] = '*/*';
      dio.options.headers['X-Requested-With'] = 'XMLHttpRequest';
      debugPrint('📡 [VOICE] Downloading voice media: $url');
      debugPrint(
        '📡 [VOICE] Download auth: token=${token != null && token.isNotEmpty}, session=${session != null && session.isNotEmpty}',
      );

      final response = await dio.download(
        url,
        filePath,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final contentType = response.headers.value(Headers.contentTypeHeader);
      debugPrint(
        '📡 [VOICE] Download status: ${response.statusCode}, content-type: ${contentType ?? 'unknown'}',
      );
      debugPrint('📡 [VOICE] Cached voice path: $filePath');
      debugPrint('✅ [VOICE] Cached: $filename');
      return filePath;
    } catch (e) {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  /// Returns true when [pathOrUrl] points to audio that iOS cannot natively play.
  /// We check both the file extension and, for cached files with generic names,
  /// we fall through to false so the caller also passes the *original* URL.
  bool _needsIosTranscode(String pathOrUrl) {
    if (!Platform.isIOS) return false;
    // Strip query-string so "file.ogg?token=xyz" is handled correctly.
    final lower = pathOrUrl.split('?').first.toLowerCase();
    return lower.endsWith('.ogg') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.webm');
  }

  /// Returns true when the server MIME type indicates a format iOS can't play.
  bool _mimeNeedsIosTranscode(String? contentType) {
    if (!Platform.isIOS || contentType == null) return false;
    final lower = contentType.toLowerCase();
    return lower.contains('audio/ogg') ||
        lower.contains('audio/webm') ||
        lower.contains('audio/opus');
  }

  Future<String> _transcodeForIos(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file missing for iOS transcode');
    }

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/voice_ios_${DateTime.now().millisecondsSinceEpoch}.m4a';

    final command =
        '-y -i "${sourceFile.path}" -c:a aac -b:a 128k -ar 44100 -ac 1 "$targetPath"';
    debugPrint('🎛️ [VOICE] Transcoding for iOS: $command');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      debugPrint('❌ [VOICE] iOS transcode failed: $logs');
      final converted = File(targetPath);
      if (await converted.exists()) {
        await converted.delete();
      }
      throw Exception('Failed to convert voice for iPhone playback');
    }

    final converted = File(targetPath);
    if (!await converted.exists()) {
      throw Exception('Converted iPhone audio file not found');
    }

    debugPrint('✅ [VOICE] iOS transcode complete: $targetPath');
    return targetPath;
  }

  Future<void> togglePlay(String url, {String? messageId}) async {
    final int requestId = ++_playbackRequestId;
    try {
      debugPrint('🎵 [VOICE] togglePlay called for: $url');
      final session = await AudioSession.instance;

      // Re-configure to playback mode every time. The record/audio_session
      // plugin switches the iOS AVAudioSession to playAndRecord during recording,
      // then deactivates it. Without re-configuring here, the first play after
      // a recording attempt has no active audio route and produces no sound.
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        ),
      );
      if (await session.setActive(true)) {
        final bool isSameMessage = messageId != null
            ? _currentAudioMessageId == messageId
            : _currentAudioUrl == url;

        if (isSameMessage) {
          if (Platform.isIOS && _usingLegacyPlayback) {
            if (_legacyPlayer.state == legacy_audio.PlayerState.playing) {
              debugPrint('⏸️ [VOICE] Pausing legacy iOS playback');
              await _legacyPlayer.pause();
              notifyListeners();
              return;
            } else {
              debugPrint('▶️ [VOICE] Resuming legacy iOS playback');
              await _legacyPlayer.resume();
              await _legacyPlayer.setPlaybackRate(_currentSpeed);
              notifyListeners();
              return;
            }
          }

          if (_player.playing) {
            debugPrint('⏸️ [VOICE] Pausing');
            await _player.pause();
            notifyListeners();
            return;
          } else {
            if (_player.processingState ==
                just_audio.ProcessingState.completed) {
              debugPrint('🔄 [VOICE] Restarting from beginning');
              await _player.seek(Duration.zero);
            }
            debugPrint('▶️ [VOICE] Resuming');
            await _player.setSpeed(_currentSpeed);
            await _player.play();
          }
        } else {
          // Switching audio: fully tear down any existing playback before
          // loading the new item. This avoids overlapping iOS players.
          await _hardResetPlayback(bumpRequest: false);

          final extension = url.split('.').last.split('?').first.toLowerCase();
          debugPrint('🎵 [VOICE] Audio Extension: $extension');
          if (extension == 'opus' || extension == 'ogg') {
            debugPrint(
              '⚠️ [VOICE] WARNING: iOS may not support OPUS/OGG natively. If playback fails, transcoding may be needed.',
            );
          }

          if (requestId != _playbackRequestId) return;
          _currentAudioUrl = url;
          _currentAudioMessageId = messageId;
          notifyListeners();

          final cachedPath = await getCachedPath(url);
          if (requestId != _playbackRequestId) return;
          String playbackPath;
          String? downloadedContentType;

          if (cachedPath != null) {
            debugPrint('🚀 [VOICE] Playing from cache: $cachedPath');
            playbackPath = cachedPath;
          } else if (url.startsWith('http')) {
            debugPrint('📡 [VOICE] Playing from URL: $url');
            try {
              final downloaded = await _downloadAndCacheWithMime(url);
              if (requestId != _playbackRequestId) return;
              playbackPath = downloaded.$1;
              downloadedContentType = downloaded.$2;
            } catch (e) {
              debugPrint('❌ [VOICE] Download failed: $e');
              rethrow;
            }
          } else {
            debugPrint('📄 [VOICE] Playing local file: $url');
            playbackPath = url;
          }

          // Check both the original URL extension AND the MIME type returned by
          // the server (captured during download). This handles cases where the
          // cached file has a generic name that doesn't reveal the codec.
          final bool iosTranscodeNeeded =
              _needsIosTranscode(playbackPath) ||
              _needsIosTranscode(url) ||
              _mimeNeedsIosTranscode(downloadedContentType);

          if (iosTranscodeNeeded) {
            debugPrint(
              '🍏 [VOICE] iOS transcode triggered (url=$url, mime=$downloadedContentType)',
            );
            playbackPath = await _transcodeForIos(playbackPath);
          }

          if (requestId != _playbackRequestId) return;
          if (Platform.isIOS) {
            _usingLegacyPlayback = false;
            await _disposeLegacyPlayer();
            if (requestId != _playbackRequestId) return;
            _legacyPlayer = _createLegacyPlayer();
            final String localPlaybackPath = _normalizeLocalPath(playbackPath);
            String iosPlaybackPath = localPlaybackPath;
            if (await File(iosPlaybackPath).exists()) {
              debugPrint('🍏 [VOICE] iOS normalizing voice file before play');
              try {
                iosPlaybackPath = await _transcodeForIos(iosPlaybackPath);
              } catch (e) {
                debugPrint('⚠️ [VOICE] iOS normalization transcode failed: $e');
              }
            }

            if (requestId != _playbackRequestId) return;
            final legacySource = await File(iosPlaybackPath).exists()
                ? legacy_audio.DeviceFileSource(iosPlaybackPath)
                : legacy_audio.UrlSource(playbackPath);
            await _legacyPlayer.setReleaseMode(legacy_audio.ReleaseMode.stop);
            await _legacyPlayer.setPlayerMode(
              legacy_audio.PlayerMode.mediaPlayer,
            );
            await _legacyPlayer.setPlaybackRate(_currentSpeed);
            if (requestId != _playbackRequestId) return;
            _currentAudioUrl = url;
            _currentAudioMessageId = messageId;
            _usingLegacyPlayback = true;
            await _legacyPlayer.play(legacySource);
            debugPrint('✅ [VOICE] legacy iOS playback started: $playbackPath');
          } else {
            final duration = await _player.setFilePath(playbackPath);
            if (duration != null && duration.inSeconds > 0) {
              _durationCache[url] = duration.inSeconds;
              if (messageId != null) {
                _durationCacheByMessageId[messageId] = duration.inSeconds;
              }
            }
            if (requestId != _playbackRequestId) return;
            debugPrint(
              '🎵 [VOICE] Loaded duration: ${duration?.inSeconds ?? 0}s',
            );
            debugPrint('🎵 [VOICE] Final playback path: $playbackPath');

            await _player.setSpeed(_currentSpeed);
            if (requestId != _playbackRequestId) return;
            debugPrint('▶️ [VOICE] Starting playback');
            await _player.play();
            debugPrint('🎵 [VOICE] Play command issued');
          }
        }
      } else {
        debugPrint('❌ [VOICE] Could not activate AudioSession');
      }
      notifyListeners();
    } catch (e) {
      final bool isCannotOpen =
          e.toString().contains('(-11828)') ||
          e.toString().contains('Cannot Open');
      if (Platform.isIOS && isCannotOpen) {
        debugPrint(
          '🍏 [VOICE] just_audio failed on iOS, trying audioplayers fallback',
        );
        try {
          if (requestId != _playbackRequestId) return;
          await _hardResetPlayback(bumpRequest: false);
          if (requestId != _playbackRequestId) return;
          _currentAudioUrl = url;
          _currentAudioMessageId = messageId;
          _usingLegacyPlayback = true;
          notifyListeners();

          await _disposeLegacyPlayer();
          if (requestId != _playbackRequestId) return;
          _legacyPlayer = _createLegacyPlayer();
          final String localUrl = _normalizeLocalPath(url);
          if (await File(localUrl).exists()) {
            final String normalizedUrl = await _transcodeForIos(localUrl);
            if (requestId != _playbackRequestId) return;
            await _legacyPlayer.setPlaybackRate(_currentSpeed);
            await _legacyPlayer.play(
              legacy_audio.DeviceFileSource(normalizedUrl),
            );
          } else {
            if (requestId != _playbackRequestId) return;
            await _legacyPlayer.setPlaybackRate(_currentSpeed);
            await _legacyPlayer.play(legacy_audio.UrlSource(url));
          }
          debugPrint('✅ [VOICE] audioplayers fallback started');
          return;
        } catch (fallbackError) {
          debugPrint('❌ [VOICE] audioplayers fallback failed: $fallbackError');
        }
      }
      await _stopInternal(clearCurrent: true, resetPosition: true);
      notifyListeners();
      debugPrint('❌ [VOICE] Playback error: $e');
    }
  }

  /// Optimized duration detection using cache and local storage
  Future<int?> getOrDetectDuration(String url, {String? messageId}) async {
    if (_durationCache.containsKey(url)) return _durationCache[url];
    if (messageId != null && _durationCacheByMessageId.containsKey(messageId)) {
      return _durationCacheByMessageId[messageId];
    }

    try {
      final cachedPath = await getCachedPath(url);
      final player = just_audio.AudioPlayer();
      Duration? d;
      String probePath;

      if (cachedPath != null) {
        debugPrint('🎵 [VOICE] Duration probe using cache: $cachedPath');
        probePath = cachedPath;
      } else if (url.startsWith('http')) {
        debugPrint('🎵 [VOICE] Duration probe downloading: $url');
        final downloaded = await _downloadAndCache(url);
        debugPrint('🎵 [VOICE] Duration probe cached file: $downloaded');
        probePath = downloaded;
      } else {
        debugPrint('🎵 [VOICE] Duration probe local file: $url');
        probePath = _normalizeLocalPath(url);
      }

      if (Platform.isIOS &&
          (_needsIosTranscode(probePath) || _needsIosTranscode(url))) {
        try {
          probePath = await _transcodeForIos(probePath);
        } catch (e) {
          debugPrint('⚠️ [VOICE] Duration probe iOS transcode failed: $e');
        }
      }

      d = await player.setFilePath(probePath);

      if (d != null) {
        _durationCache[url] = d.inSeconds;
        if (messageId != null) {
          _durationCacheByMessageId[messageId] = d.inSeconds;
        }
        await player.dispose();
        return d.inSeconds;
      }
      await player.dispose();
    } catch (e) {
      debugPrint('⚠️ [VOICE] Duration detection error: $e');
    }
    return null;
  }

  Future<void> stop() async {
    await _stopInternal(clearCurrent: true, resetPosition: true);
    await _legacyPlayer.stop();
    await _legacyPlayer.release();
    _usingLegacyPlayback = false;
    notifyListeners();
  }

  Future<void> _stopInternal({
    required bool clearCurrent,
    required bool resetPosition,
    bool bumpRequest = true,
  }) async {
    if (bumpRequest) _playbackRequestId++;
    _isBuffering = false;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _legacyPlayer.stop();
    } catch (_) {}
    try {
      await _legacyPlayer.release();
    } catch (_) {}
    if (clearCurrent) {
      _usingLegacyPlayback = false;
    }

    if (resetPosition) {
      try {
        await _player.seek(Duration.zero);
      } catch (_) {}
    }

    if (clearCurrent) {
      _currentAudioUrl = null;
      _currentAudioMessageId = null;
    }
  }

  Future<void> _hardResetPlayback({bool bumpRequest = true}) async {
    if (bumpRequest) {
      _playbackRequestId++;
    }
    _isBuffering = false;
    _usingLegacyPlayback = false;
    _currentAudioUrl = null;
    _currentAudioMessageId = null;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _player.seek(Duration.zero);
    } catch (_) {}
    await _disposeLegacyPlayer();
    _legacyPlayer = _createLegacyPlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    _legacyPlayer.dispose();
    super.dispose();
  }
}
