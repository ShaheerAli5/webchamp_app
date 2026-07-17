# Implementation Plan - Fix Voice Playback (Iteration 2)

The previous fix for voice playback was incomplete due to missing initialization and potential session conflicts. This iteration focuses on robust `AVAudioSession` management and better format support.

## User Review Required

> [!IMPORTANT]
> I am moving the `AVAudioSession` configuration to be more aggressive, applying it right before every playback to ensure no other components (like the recorder or Agora) have left the session in an incompatible state.

- **Audio Format**: If the voice messages are in Opus/OGG format, they will not play on iOS natively. I will add logging to identify the format. If confirmed, we may need a transcoding solution or a player that supports Opus.

## Proposed Changes

### Audio Playback Manager

#### [MODIFY] [voice_playback_manager.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/core/utils/voice_playback_manager.dart)
- Correctly import `audio_session`.
- Ensure `_initAudioSession()` is called in the constructor.
- Re-configure the session to `playback` right before `setActive(true)` in `togglePlay`.
- Add detailed logging for playback errors and audio source info.
- Add a fallback mechanism or clear error if the format is incompatible (e.g. `.opus` on iOS).

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///C:/Users/muham/Documents/GitHub/webchamp_app/pubspec.yaml)
- Verify `audio_session` is present (it should be from previous step, but I will double check).

## Verification Plan

### Manual Verification
- **Recorded Voice**: Record a voice message and play it back immediately.
- **Received Voice**: Play a received voice message.
- **Logs**: Check Flutter logs for "❌ [VOICE]" or "📡 [VOICE]" prefixes to see what's happening during playback.
