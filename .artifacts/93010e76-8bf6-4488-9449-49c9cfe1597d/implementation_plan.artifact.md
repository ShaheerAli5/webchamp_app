# Implementation Plan - Fix iOS-Specific Issues

Investigate and fix issues related to voice message playback, camera access, and video recording on iOS.

## User Review Required

> [!IMPORTANT]
> The issues are primarily caused by missing iOS-specific configurations in `Info.plist` and lack of `AVAudioSession` management for audio playback.

- **Permissions**: I will be adding several permission strings to `ios/Runner/Info.plist`. If you have specific wording you'd like for these (e.g., "Wab Champ needs camera access to take photos"), please let me know. I will use standard, clear descriptions.
- **Audio Session**: I will configure the app to play audio even when the phone is on silent mode, which is standard for voice messages in chat apps.

## Proposed Changes

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///C:/Users/muham/Documents/GitHub/webchamp_app/pubspec.yaml)
- Add `audio_session` dependency to allow explicit management of iOS audio sessions.

### iOS Configuration

#### [MODIFY] [Info.plist](file:///C:/Users/muham/Documents/GitHub/webchamp_app/ios/Runner/Info.plist)
- Add `NSCameraUsageDescription` for camera access.
- Add `NSMicrophoneUsageDescription` for video recording and voice messages.
- Add `NSPhotoLibraryUsageDescription` and `NSPhotoLibraryAddUsageDescription` for saving/selecting media.
- Add `UIBackgroundModes` with `audio` to support background playback.

### Audio Playback & Recording

#### [MODIFY] [voice_playback_manager.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/core/utils/voice_playback_manager.dart)
- Integrate `audio_session` package to configure `AVAudioSession`.
- Set category to `playback` with options to support Bluetooth and DuckOthers.
- Ensure the session is active before playback.

#### [MODIFY] [individual_chat_screen.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/ui/screens/chat/individual_chat_screen.dart)
- Configure `AudioSession` for `playAndRecord` before starting a voice recording to ensure high-quality recording and proper session management.

### Camera & Video Recording

#### [MODIFY] [whatsapp_camera_screen.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/ui/screens/chat/widgets/whatsapp_camera_screen.dart)
- Improve error logging for camera initialization to help debug if issues persist on specific devices.
- Ensure `enableAudio: true` is correctly handled (already present, but will verify).

## Verification Plan

### Automated Tests
- Since these are hardware-dependent and iOS-specific, automated unit tests have limited utility for the root causes. I will focus on ensuring the code builds and the logic for permission requests and session configuration is sound.

### Manual Verification
- **Voice Messages**: Play a voice message on an iPhone. Verify it plays even if the silent switch is ON.
- **Camera**: Open the camera in the chat. Verify the permission dialog appears with the custom description. Verify the camera preview starts.
- **Photo/Video**: Take a photo and record a video. Verify they are captured and returned to the chat screen successfully.
- **Microphone**: Verify audio is captured in recorded videos.
- **Regressions**: Verify Android functionality remains unchanged.
