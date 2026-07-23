import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraMode { photo, video }

class WhatsAppCameraScreen extends StatefulWidget {
  const WhatsAppCameraScreen({super.key});

  @override
  State<WhatsAppCameraScreen> createState() => _WhatsAppCameraScreenState();
}

class _WhatsAppCameraScreenState extends State<WhatsAppCameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  CameraDescription? _activeCamera;
  bool _isReady = false;
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  Timer? _timer;
  FlashMode _flashMode = FlashMode.off;
  int _selectedCameraIndex = 0;
  CameraMode _mode = CameraMode.photo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      debugPrint("❌ [CAMERA] No cameras available");
      return;
    }

    await _onNewCameraSelected(_cameras[_selectedCameraIndex]);
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    debugPrint("📸 [CAMERA] Selecting camera: ${cameraDescription.name}");
    _activeCamera = cameraDescription;
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      await _controller!.setFlashMode(_flashMode);
      debugPrint("✅ [CAMERA] Camera initialized successfully");

      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    } catch (e) {
      debugPrint("❌ [CAMERA] Initialization Error: $e");
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            debugPrint('User denied camera access.');
            break;
          default:
            debugPrint('Handle other errors: ${e.code}');
            break;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
      _isReady = false;
    } else if (state == AppLifecycleState.resumed) {
      final camera = _activeCamera;
      if (camera != null) {
        _onNewCameraSelected(camera);
      }
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    FlashMode nextMode;
    if (_flashMode == FlashMode.off) {
      nextMode = FlashMode.always;
    } else if (_flashMode == FlashMode.always) {
      nextMode = FlashMode.auto;
    } else {
      nextMode = FlashMode.off;
    }

    await _controller!.setFlashMode(nextMode);
    setState(() {
      _flashMode = nextMode;
    });
  }

  void _switchCamera() {
    if (_cameras.length < 2 || _isRecording) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _onNewCameraSelected(_cameras[_selectedCameraIndex]);
  }

  Future<void> _takePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isRecording)
      return;

    try {
      final XFile photo = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, {'path': photo.path, 'type': 'image'});
      }
    } catch (e) {
      debugPrint("Take photo error: $e");
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isRecording)
      return;

    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint("❌ [CAMERA] Microphone permission denied");
        return;
      }
      if (_controller == null || !_controller!.value.isInitialized) {
        return;
      }
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordDuration = 0;
      });
      _startTimer();
    } catch (e) {
      debugPrint("Start recording error: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRecording && !_isPaused) {
        setState(() {
          _recordDuration++;
        });
        if (_recordDuration >= 240) {
          _stopRecording();
          _showLimitReachedMessage();
        }
      }
    });
  }

  void _showLimitReachedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Maximum recording time is 4 minutes."),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _pauseRecording() async {
    if (_controller == null || !_isRecording || _isPaused) return;

    try {
      await _controller!.pauseVideoRecording();
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      debugPrint("Pause recording error: $e");
    }
  }

  Future<void> _resumeRecording() async {
    if (_controller == null || !_isRecording || !_isPaused) return;

    try {
      await _controller!.resumeVideoRecording();
      setState(() {
        _isPaused = false;
      });
    } catch (e) {
      debugPrint("Resume recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    _timer?.cancel();
    try {
      final XFile video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      if (_recordDuration < 1) {
        File(video.path).delete();
        return;
      }

      if (mounted) {
        Navigator.pop(context, {'path': video.path, 'type': 'video'});
      }
    } catch (e) {
      debugPrint("Stop recording error: $e");
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00CF9D)),
        ),
      );
    }

    // Full screen logic: Scale preview to cover screen
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-Screen Camera Preview
          Positioned.fill(
            child: Transform.scale(
              scale: scale,
              child: Center(child: CameraPreview(_controller!)),
            ),
          ),

          // Gradient for controls visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleFlash,
                          icon: Icon(
                            _flashMode == FlashMode.off
                                ? Icons.flash_off
                                : (_flashMode == FlashMode.always
                                      ? Icons.flash_on
                                      : Icons.flash_auto),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        if (!_isRecording)
                          IconButton(
                            onPressed: _switchCamera,
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recording Duration & Paused Indicator
          if (_isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60.h,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: _isPaused ? Colors.grey : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _formatDuration(_recordDuration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            " / 04:00",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isPaused)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          "PAUSED",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: const [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Bottom Bar Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode Switcher (PHOTO / VIDEO)
                  if (!_isRecording)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Text(
                        _mode == CameraMode.video ? "Max Recording: 4:00" : "",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (!_isRecording)
                    Padding(
                      padding: EdgeInsets.only(bottom: 20.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildModeItem("PHOTO", CameraMode.photo),
                          SizedBox(width: 30.w),
                          _buildModeItem("VIDEO", CameraMode.video),
                        ],
                      ),
                    ),

                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 30.h,
                      left: 30.w,
                      right: 30.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Gallery / Pause
                        if (_isRecording)
                          IconButton(
                            onPressed: _isPaused
                                ? _resumeRecording
                                : _pauseRecording,
                            icon: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.white,
                              size: 36,
                            ),
                          )
                        else
                          IconButton(
                            onPressed: () {}, // Future: Implement Gallery
                            icon: const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),

                        // Center: Capture Button
                        GestureDetector(
                          onTap: () {
                            if (_isRecording) {
                              _stopRecording();
                            } else {
                              if (_mode == CameraMode.photo) {
                                _takePhoto();
                              } else {
                                _startRecording();
                              }
                            }
                          },
                          onLongPress: () {
                            if (!_isRecording && _mode == CameraMode.photo) {
                              _startRecording();
                            }
                          },
                          onLongPressUp: () {
                            if (_isRecording && _mode == CameraMode.photo) {
                              _stopRecording();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isRecording ? 40.w : 64.w,
                                height: _isRecording ? 40.w : 64.w,
                                decoration: BoxDecoration(
                                  color: _isRecording
                                      ? Colors.red
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(
                                    _isRecording ? 8.r : 32.r,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right: Switch Camera
                        if (_isRecording)
                          const SizedBox(width: 48)
                        else
                          IconButton(
                            onPressed: _switchCamera,
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem(String label, CameraMode mode) {
    final bool isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00CF9D) : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
