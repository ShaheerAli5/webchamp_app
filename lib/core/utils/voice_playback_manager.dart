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
        _currentAudioUrl = null; // Revert to avatar when finished
      }
      notifyListeners();
    });

    _player.positionStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
  }

  late final AudioPlayer _player;
  String? _currentAudioUrl;
  double _currentSpeed = 1.0;

  AudioPlayer get player => _player;
  String? get currentAudioUrl => _currentAudioUrl;
  bool get isPlaying => _player.playing;
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
          await _player.play();
        }
      } else {
        await _player.stop();
        _currentAudioUrl = url;
        
        try {
          if (url.startsWith('http')) {
            await _player.setUrl(url);
          } else {
            await _player.setFilePath(url);
          }
        } catch (e) {
          debugPrint('⚠️ [VOICE] Playback error: $e. Attempting fallback...');
          // Fallback: Download the file if it's a URL and network playback failed
          // This fixes "Unsupported Audio mime type text/plain" errors from broken servers
          if (url.startsWith('http')) {
            try {
              final dir = await getTemporaryDirectory();
              final filename = url.split('/').last.split('?').first; // Basic filename extraction
              final filePath = '${dir.path}/cache_$filename';
              final file = File(filePath);
              
              if (!await file.exists()) {
                debugPrint('📥 [VOICE] Downloading for local playback: $url');
                await Dio().download(url, filePath);
              }
              
              await _player.setFilePath(filePath);
            } catch (fallbackError) {
              debugPrint('❌ [VOICE] Fallback failed: $fallbackError');
              _currentAudioUrl = null;
              rethrow;
            }
          } else {
            _currentAudioUrl = null;
            rethrow;
          }
        }
        await _player.setSpeed(_currentSpeed);
        await _player.play();
      }
      notifyListeners();
    } catch (e) {
      _currentAudioUrl = null;
      notifyListeners();
      debugPrint('Error playing voice message: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentAudioUrl = null;
    notifyListeners();
  }

  void disposePlayer() {
    _player.dispose();
  }
}
