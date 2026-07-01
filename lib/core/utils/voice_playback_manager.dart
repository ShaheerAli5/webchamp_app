import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

/// A singleton manager to handle voice message playback across the app.
/// This ensures only one voice message plays at a time and maintains state during scrolling.
class VoicePlaybackManager extends ChangeNotifier {
  static final VoicePlaybackManager _instance = VoicePlaybackManager._internal();
  factory VoicePlaybackManager() => _instance;

  VoicePlaybackManager._internal() {
    _player = AudioPlayer();
    
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
        _currentAudioUrl = null;
      }
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      final bool buffering = state == ProcessingState.buffering || state == ProcessingState.loading;
      if (_isBuffering != buffering) {
        _isBuffering = buffering;
        notifyListeners();
      }
    });

    _player.positionStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
  }

  late final AudioPlayer _player;
  String? _currentAudioUrl;
  double _currentSpeed = 1.0;
  bool _isBuffering = false;
  
  final Set<String> _preloadingUrls = {};
  final Map<String, int> _durationCache = {};

  AudioPlayer get player => _player;
  String? get currentAudioUrl => _currentAudioUrl;
  bool get isPlaying => _player.playing;
  bool get isBuffering => _isBuffering;
  double get currentSpeed => _currentSpeed;

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
    final lastPart = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'voice';
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
      await Dio().download(
        url, 
        filePath,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      debugPrint('✅ [VOICE] Cached: $filename');
      return filePath;
    } catch (e) {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<void> togglePlay(String url) async {
    try {
      if (_currentAudioUrl == url) {
        if (_player.playing) {
          await _player.pause();
        } else {
          if (_player.processingState == ProcessingState.completed) {
            await _player.seek(Duration.zero);
          }
          await _player.setSpeed(_currentSpeed);
          _player.play();
        }
      } else {
        // Switching audio: stop current and prepare new one
        // We stop previous playback immediately for better UX
        if (_player.playing) await _player.stop();
        
        _currentAudioUrl = url;
        notifyListeners(); // Trigger UI to show buffering/loading

        final cachedPath = await getCachedPath(url);
        
        if (cachedPath != null) {
          debugPrint('🚀 [VOICE] Instant play from cache: $cachedPath');
          await _player.setFilePath(cachedPath);
        } else {
          debugPrint('📡 [VOICE] Streaming from URL: $url');
          // Start streaming while also caching in background
          // Use Future.wait to start both but we only care about player readiness
          _player.setUrl(url).catchError((e) {
            debugPrint('❌ [VOICE] Streaming error: $e');
            return null;
          });
          _downloadAndCache(url).catchError((_) => '');
        }
        
        await _player.setSpeed(_currentSpeed);
        _player.play(); // play() will wait for source readiness internally
      }
      notifyListeners();
    } catch (e) {
      _currentAudioUrl = null;
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
        d = await player.setFilePath(cachedPath);
      } else if (url.startsWith('http')) {
        d = await player.setUrl(url);
      } else {
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
    await _player.stop();
    _currentAudioUrl = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
