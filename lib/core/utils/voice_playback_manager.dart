import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
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
    _player = AudioPlayer();
    _initAudioSession();

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _stopInternal(clearCurrent: true, resetPosition: true);
      }
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      final bool buffering =
          state == ProcessingState.buffering ||
          state == ProcessingState.loading;
      if (_isBuffering != buffering) {
        _isBuffering = buffering;
        notifyListeners();
      }
    });

    // 🛡️ PERFORMANCE: Do NOT call notifyListeners() on every position update.
    // This was causing massive jank as all bubbles were rebuilding.
    // _player.positionStream.listen((_) => notifyListeners());
    // _player.durationStream.listen((_) => notifyListeners());
  }

  late final AudioPlayer _player;
  String? _currentAudioUrl;
  double _currentSpeed = 1.0;
  bool _isBuffering = false;
  int _playbackRequestId = 0;

  final Set<String> _preloadingUrls = {};
  final Map<String, int> _durationCache = {};
  final SecureStorageService _storageService = SecureStorageService();

  AudioPlayer get player => _player;
  String? get currentAudioUrl => _currentAudioUrl;
  bool get isPlaying => _player.playing;
  bool get isBuffering => _isBuffering;
  double get currentSpeed => _currentSpeed;

  // 🚀 Added streams for granular UI updates
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

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

  void setSpeed(double speed) {
    _currentSpeed = speed;
    _player.setSpeed(speed);
    notifyListeners();
  }

  void toggleSpeed() {
    if (_currentSpeed == 1.0) {
      setSpeed(1.5);
    } else if (_currentSpeed == 1.5) {
      setSpeed(2.0);
    } else {
      setSpeed(1.0);
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
    // Generate a unique filename based on the URL to avoid collisions
    // Using a hash would be safer, but for now we take the last part
    final uri = Uri.parse(url);
    final lastPart = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'voice';
    final queryHash = uri.query.hashCode.toRadixString(36);
    return '${lastPart}_$queryHash';
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

  bool _needsIosTranscode(String url) {
    if (!Platform.isIOS) return false;
    final lower = url.split('?').first.toLowerCase();
    return lower.endsWith('.ogg') || lower.endsWith('.opus');
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

  Future<void> togglePlay(String url) async {
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
        if (_currentAudioUrl == url) {
          if (_player.playing) {
            debugPrint('⏸️ [VOICE] Pausing');
            await _player.pause();
            notifyListeners();
            return;
          } else {
            if (_player.processingState == ProcessingState.completed) {
              debugPrint('🔄 [VOICE] Restarting from beginning');
              await _player.seek(Duration.zero);
            }
            debugPrint('▶️ [VOICE] Resuming');
            await _player.setSpeed(_currentSpeed);
            await _player.play();
          }
        } else {
          // Switching audio: stop current and fully reset before loading new item.
          await _stopInternal(
            clearCurrent: true,
            resetPosition: true,
            bumpRequest: false,
          );

          final extension = url.split('.').last.split('?').first.toLowerCase();
          debugPrint('🎵 [VOICE] Audio Extension: $extension');
          if (extension == 'opus' || extension == 'ogg') {
            debugPrint(
              '⚠️ [VOICE] WARNING: iOS may not support OPUS/OGG natively. If playback fails, transcoding may be needed.',
            );
          }

          if (requestId != _playbackRequestId) return;
          _currentAudioUrl = url;
          notifyListeners();

          final cachedPath = await getCachedPath(url);
          String playbackPath;

          if (cachedPath != null) {
            debugPrint('🚀 [VOICE] Playing from cache: $cachedPath');
            playbackPath = cachedPath;
          } else if (url.startsWith('http')) {
            debugPrint('📡 [VOICE] Playing from URL: $url');
            try {
              final downloaded = await _downloadAndCache(url);
              playbackPath = downloaded;
            } catch (e) {
              debugPrint('❌ [VOICE] Download failed: $e');
              rethrow;
            }
          } else {
            debugPrint('📄 [VOICE] Playing local file: $url');
            playbackPath = url;
          }

          if (_needsIosTranscode(playbackPath) || _needsIosTranscode(url)) {
            debugPrint(
              '🍏 [VOICE] iOS fallback triggered for unsupported audio',
            );
            playbackPath = await _transcodeForIos(playbackPath);
          }

          if (requestId != _playbackRequestId) return;
          final duration = await _player.setFilePath(playbackPath);
          debugPrint(
            '🎵 [VOICE] Loaded duration: ${duration?.inSeconds ?? 0}s',
          );
          debugPrint('🎵 [VOICE] Final playback path: $playbackPath');

          await _player.setSpeed(_currentSpeed);
          debugPrint('▶️ [VOICE] Starting playback');
          if (requestId == _playbackRequestId) {
            await _player.play();
            debugPrint('🎵 [VOICE] Play command issued');
          }
        }
      } else {
        debugPrint('❌ [VOICE] Could not activate AudioSession');
      }
      notifyListeners();
    } catch (e) {
      await _stopInternal(clearCurrent: true, resetPosition: true);
      notifyListeners();
      debugPrint('❌ [VOICE] Playback error: $e');
    }
  }

  /// Optimized duration detection using cache and local storage
  Future<int?> getOrDetectDuration(String url) async {
    if (_durationCache.containsKey(url)) return _durationCache[url];

    try {
      final cachedPath = await getCachedPath(url);
      final player = AudioPlayer();
      Duration? d;

      if (cachedPath != null) {
        debugPrint('🎵 [VOICE] Duration probe using cache: $cachedPath');
        d = await player.setFilePath(cachedPath);
      } else if (url.startsWith('http')) {
        debugPrint('🎵 [VOICE] Duration probe downloading: $url');
        final downloaded = await _downloadAndCache(url);
        debugPrint('🎵 [VOICE] Duration probe cached file: $downloaded');
        d = await player.setFilePath(downloaded);
      } else {
        debugPrint('🎵 [VOICE] Duration probe local file: $url');
        d = await player.setFilePath(url);
      }

      if (d != null) {
        _durationCache[url] = d.inSeconds;
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

    if (resetPosition) {
      try {
        await _player.seek(Duration.zero);
      } catch (_) {}
    }

    if (clearCurrent) {
      _currentAudioUrl = null;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
