import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../../core/utils/helpers.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';
import 'widgets/voice_message_bubble.dart';
import 'widgets/video_player_widget.dart';
import 'widgets/whatsapp_camera_screen.dart';
import 'status_edit_screen.dart';

enum RecordingState { idle, recording, locked, preview }

class IndividualChatScreen extends StatefulWidget {
  final String uid;
  final String name;
  const IndividualChatScreen({super.key, required this.uid, required this.name});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;
  bool _isSending = false;
  String _loadingMessage = 'Loading conversation...';
  
  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isAppInBackground = false;
  Map<String, dynamic>? _replyingTo;
  String? _selectedMessageId;

  final AudioRecorder _audioRecorder = AudioRecorder();
  RecordingState _recordingState = RecordingState.idle;
  String? _recordedFilePath;
  int _recordDuration = 0;
  Timer? _recordTimer;
  late RecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
      
    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty != _isTyping) {
        setState(() {
          _isTyping = _messageController.text.isNotEmpty;
        });
      }
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmoji = false;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatData();
      _startPolling();
    });
  }

  String _sanitizeText(String? text) {
    if (text == null) return '';
    return Helpers.htmlToPlainText(Helpers.sanitizeString(text)).trim();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppInBackground = true;
      _pollingTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _isAppInBackground = false;
      _startPolling();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    if (_isAppInBackground) return;
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      final provider = context.read<ContactProvider>();
      // 🛡️ Only poll if this screen's UID is the active one in the provider AND app is in foreground
      if (mounted && !_isPolling && provider.activeChatUid == widget.uid && !_isAppInBackground) {
        _isPolling = true;
        try {
          // 🚀 Pass pollOnly: true to skip metadata requests during frequent polls
          await provider.getContactChatBoxData(widget.uid, showLoading: false, refresh: true, pollOnly: true);
        } catch (e) {
          debugPrint('❌ [CHAT] Polling error: $e');
        } finally {
          if (mounted) _isPolling = false;
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _recorderController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    
    // Clear chat data from provider to avoid seeing old messages when opening a new chat
    // Use context.read safely as it might be called during/after unmount
    try {
      if (mounted) {
        context.read<ContactProvider>().clearChat();
      }
    } catch (e) {
      debugPrint(' [CHAT] Could not clear chat on dispose: $e');
    }

    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // ️ Request microphone permission explicitly using permission_handler
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        Fluttertoast.showToast(msg: "Microphone permission denied");
        return;
      }

      // Configure AudioSession for recording on iOS
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      ));
      await session.setActive(true);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordedFilePath = path;
      
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, 
        bitRate: 128000, 
        sampleRate: 44100,
        numChannels: 1,
      );
      await _audioRecorder.start(config, path: path);
      
      // 🛡 Waveform recording can sometimes fail due to plugin linking issues
      try {
        await _recorderController.record();
      } catch (e) {
        debugPrint("📊 [WAVEFORM] Failed to start waveform recorder: $e");
        // We continue even if waveform fails so recording isn't blocked
      }
      
      setState(() { 
        _recordingState = RecordingState.recording;
        _recordDuration = 0; 
      });
      
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() { _recordDuration++; });
      });
    } catch (e) {
      debugPrint(" [RECORD] Start recording error: $e");
      Fluttertoast.showToast(msg: "Failed to start recording");
      
      // Reset state on error
      setState(() {
        _recordingState = RecordingState.idle;
        _recordDuration = 0;
        _recordedFilePath = null;
      });
    }
  }

  Future<void> _lockRecording() async {
    setState(() {
      _recordingState = RecordingState.locked;
    });
  }

  Future<void> _stopRecording({bool sendImmediately = false}) async {
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();
      await _recorderController.stop();

      // Deactivate AudioSession after recording
      try {
        final session = await AudioSession.instance;
        await session.setActive(false);
      } catch (e) {
        debugPrint("⚠️ [SESSION] Deactivation error: $e");
      }
      
      if (path != null && _recordDuration > 0) {
        if (sendImmediately) {
          _sendVoiceMessage(path);
          setState(() {
            _recordingState = RecordingState.idle;
            _recordedFilePath = null;
          });
        } else {
          setState(() {
            _recordingState = RecordingState.preview;
            _recordedFilePath = path;
          });
        }
      } else {
        setState(() {
          _recordingState = RecordingState.idle;
          _recordedFilePath = null;
        });
      }
    } catch (e) {
      debugPrint("Stop recording error: $e");
      setState(() { _recordingState = RecordingState.idle; });
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _recordTimer?.cancel();
      await _audioRecorder.stop();
      await _recorderController.stop();

      // Deactivate AudioSession after cancellation
      try {
        final session = await AudioSession.instance;
        await session.setActive(false);
      } catch (e) {
        debugPrint("⚠️ [SESSION] Deactivation error: $e");
      }

      setState(() { 
        _recordingState = RecordingState.idle;
        _recordDuration = 0; 
        _recordedFilePath = null;
      });
    } catch (e) {
      debugPrint("Cancel recording error: $e");
      setState(() { _recordingState = RecordingState.idle; });
    }
  }

  void _sendVoiceMessage(String path) {
    if (_isSending) return;
    setState(() => _isSending = true);
    debugPrint('[VOICE] Sending voice message. Path: $path');
    
    context.read<ContactProvider>().sendVoiceMessage(
      contactUid: widget.uid,
      filePath: path,
      duration: _recordDuration,
    ).then((success) {
      if (mounted) setState(() => _isSending = false);
    }).catchError((e) {
      if (mounted) setState(() => _isSending = false);
    });
    
    _scrollToBottom();
  }

  void _handleVoiceSend() {
    if (_recordedFilePath != null) {
      _sendVoiceMessage(_recordedFilePath!);
      setState(() {
        _recordingState = RecordingState.idle;
        _recordedFilePath = null;
      });
    }
  }

  Future<void> _handleCamera() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const WhatsAppCameraScreen()),
    );

    if (result != null && result['path'] != null) {
      final previewResult = await _showMediaPreview(result['path'], result['type']);
      if (previewResult == 'retake') {
        _handleCamera();
      }
    }
  }

  Future<dynamic> _showMediaPreview(String path, String type) async {
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusEditScreen(
          path: path,
          type: type,
          onSend: (caption, {newPath, newType}) {
            _messageController.text = caption;
            if (newPath != null) path = newPath;
            if (newType != null) type = newType;
            Navigator.pop(context, true);
          },
        ),
      ),
    );

    if (result == true && mounted) {
      if (type == 'image') _sendImage(path);
      else if (type == 'video') _sendVideo(path);
      else if (type == 'document') _sendDocument(path);
      else if (type == 'sticker') _sendSticker(path);
    }
    return result;
  }

  Future<void> _handleAttachment() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 250.h,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Text("Select attachment", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(Icons.image, "Gallery", Colors.purple, () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null && mounted) {
                    Navigator.pop(context, 'image:${image.path}');
                  }
                }),
                _buildAttachmentOption(Icons.videocam, "Video", Colors.orange, () async {
                  final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                  if (video != null && mounted) {
                    // 🛡 LIMIT: Gallery videos up to 6 minutes (360 seconds)
                    try {
                      final info = await VideoCompress.getMediaInfo(video.path);
                      final durationMs = info.duration ?? 0;
                      if (durationMs > 360000) {
                        if (mounted) {
                          Navigator.pop(context);
                          _showErrorDialog("Videos longer than 6 minutes cannot be sent. Please select a shorter video.");
                        }
                        return;
                      }
                    } catch (e) {
                      debugPrint("⚠ [VIDEO] Could not get duration: $e");
                    }
                    
                    if (mounted) Navigator.pop(context, 'video:${video.path}');
                  }
                }),
                _buildAttachmentOption(Icons.insert_drive_file, "Document", Colors.blue, () async {
                  FilePickerResult? res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip'],
                  );
                  if (res != null && mounted) {
                    Navigator.pop(context, 'file:${res.files.single.path}');
                  }
                }),
                _buildAttachmentOption(Icons.sticky_note_2, "Sticker", Colors.teal, () async {
                  FilePickerResult? res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['webp'],
                  );
                  if (res != null && mounted) {
                    Navigator.pop(context, 'sticker:${res.files.single.path}');
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      if (result.startsWith('image:')) {
        _showMediaPreview(result.substring(6), 'image');
      } else if (result.startsWith('video:')) {
        _showMediaPreview(result.substring(6), 'video');
      } else if (result.startsWith('file:')) {
        _showMediaPreview(result.substring(5), 'document');
      } else if (result.startsWith('sticker:')) {
        _showMediaPreview(result.substring(8), 'sticker');
      }
    }
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 30.r, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 28.sp)),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }

  void _sendImage(String path) {
    if (_isSending) return;
    setState(() => _isSending = true);
    context.read<ContactProvider>().sendImageMessage(contactUid: widget.uid, filePath: path).then((_) {
      if (mounted) setState(() => _isSending = false);
    }).catchError((_) {
      if (mounted) setState(() => _isSending = false);
    });
    _scrollToBottom();
  }

  void _sendVideo(String path) {
    if (_isSending) return;
    setState(() => _isSending = true);
    context.read<ContactProvider>().sendVideoMessage(contactUid: widget.uid, filePath: path).then((_) {
      if (mounted) setState(() => _isSending = false);
    }).catchError((_) {
      if (mounted) setState(() => _isSending = false);
    });
    _scrollToBottom();
  }

  void _sendDocument(String path) {
    if (_isSending) return;
    setState(() => _isSending = true);
    context.read<ContactProvider>().sendDocumentMessage(contactUid: widget.uid, filePath: path).then((_) {
      if (mounted) setState(() => _isSending = false);
    }).catchError((_) {
      if (mounted) setState(() => _isSending = false);
    });
    _scrollToBottom();
  }

  void _sendSticker(String path) {
    if (_isSending) return;
    setState(() => _isSending = true);
    context.read<ContactProvider>().sendStickerMessage(contactUid: widget.uid, filePath: path).then((_) {
      if (mounted) setState(() => _isSending = false);
    }).catchError((_) {
      if (mounted) setState(() => _isSending = false);
    });
    _scrollToBottom();
  }

  void _onEmojiSelected(Emoji emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    
    // Default to end of text if no selection
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, emoji.emoji);
    _messageController.text = newText;
    
    // Set cursor after the inserted emoji
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: start + emoji.emoji.length),
    );
  }

  void _toggleEmoji() {
    if (_showEmoji) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
    setState(() {
      _showEmoji = !_showEmoji;
    });
  }

  void _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && !_isSending) {
      debugPrint('🖱 [UI] Send button tapped');
      setState(() => _isSending = true);
      
      final provider = context.read<ContactProvider>();
      final replyId = _replyingTo?['whatsapp_message_id'] ?? _replyingTo?['wamid'];
      
      _messageController.clear();
      if (_replyingTo != null) {
        setState(() { _replyingTo = null; });
      }
      
      provider.sendMessage(
        contactUid: widget.uid, 
        message: text, 
        replyToMessageId: replyId?.toString()
      ).then((_) {
        if (mounted) setState(() => _isSending = false);
      }).catchError((_) {
        if (mounted) setState(() => _isSending = false);
      });
      
      _scrollToBottom();
    }
  }

  void _showContactInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ContactProvider>(
        builder: (context, provider, child) {
          final contact = provider.contacts.firstWhere((c) => (c['_uid'] ?? c['uid']) == widget.uid, orElse: () => <String, dynamic>{});
          final name = contact['full_name'] ?? contact['first_name'] ?? widget.name;
          final imageUrl = contact['profile_image'] ?? contact['image_url'];
          return Container(
            height: 0.85.sh,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r))),
                SizedBox(height: 20.h),
                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: const Color(0xFFF0F2F5),
                  backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
                  child: imageUrl == null ? Text(Helpers.getInitial(name), style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.grey)) : null,
                ),
                SizedBox(height: 12.h),
                Text(_sanitizeText(name), style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/edit-contact', extra: contact).then((_) => provider.getContacts());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007176), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r))),
                  child: const Text("Edit Contact"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Selector<ContactProvider, Map<String, dynamic>>(
          selector: (_, provider) {
            return provider.selectedContact != null && 
                           (provider.selectedContact!['_uid'] ?? provider.selectedContact!['uid']) == widget.uid
                ? provider.selectedContact!
                : provider.contacts.firstWhere(
                    (c) => (c['_uid'] ?? c['uid']) == widget.uid, 
                    orElse: () => <String, dynamic>{}
                  );
          },
          builder: (context, contact, child) {
            final name = contact['full_name'] ?? contact['first_name'] ?? widget.name;
            final imageUrl = contact['profile_image'] ?? contact['image_url'];
            return ChatAppBar(name: _sanitizeText(name), uid: widget.uid, imageUrl: imageUrl, onInfoTap: _showContactInfo);
          },
        ),
      ),
      body: PopScope(
        canPop: !_showEmoji,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _showEmoji) {
            setState(() {
              _showEmoji = false;
            });
          }
        },
        child: GestureDetector(
          onTap: () { 
            if (_selectedMessageId != null) setState(() => _selectedMessageId = null); 
            if (_showEmoji) setState(() => _showEmoji = false);
            if (_focusNode.hasFocus) _focusNode.unfocus();
          },
          child: Stack(
            children: [
              // WhatsApp-style Doodle Background
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFE9EDEF), // Light WhatsApp beige
                  child: Opacity(
                    opacity: 0.4, // Increased opacity to make it visible
                    child: Image.asset(
                      'assets/images/whatsapp_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if the local asset is missing
                        return Image.network(
                          'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.2),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: !_showEmoji,
                child: Column(
                  children: [
                    const ChatCountdownTimer(),
                    Expanded(
                      child: Selector<ContactProvider, _ChatStateData>(
                        selector: (_, provider) => _ChatStateData(
                          messages: provider.messages,
                          isLoading: provider.isLoading,
                          errorMessage: provider.errorMessage,
                        ),
                        builder: (context, data, child) {
                          final messages = data.messages;
                          final isLoading = data.isLoading;
                          final errorMessage = data.errorMessage;

                          if (isLoading && messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(color: Color(0xFF00A884)),
                                  SizedBox(height: 16.h),
                                  Text(
                                    _loadingMessage,
                                    style: TextStyle(color: const Color(0xFF667781), fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (errorMessage != null && messages.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                                    SizedBox(height: 16.h),
                                    Text(
                                      errorMessage,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: const Color(0xFF667781), fontSize: 14.sp),
                                    ),
                                    SizedBox(height: 16.h),
                                    ElevatedButton(
                                      onPressed: () => context.read<ContactProvider>().getContactChatBoxData(widget.uid, refresh: true),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008069), foregroundColor: Colors.white),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Optimized: Pass message list to builder
                          return _buildMessagesList(messages, null);
                        },
                      ),
                    ),
                    ChatInputBar(
                      controller: _messageController,
                      focusNode: _focusNode,
                      isTyping: _isTyping,
                      isSending: _isSending,
                      showEmoji: _showEmoji,
                      onAttachment: _handleAttachment,
                      onCamera: _handleCamera,
                      onSend: _handleSend,
                      replyingTo: _replyingTo,
                      onCancelReply: () => setState(() => _replyingTo = null),
                      recordingState: _recordingState,
                      recordDuration: _recordDuration,
                      onStartRecording: _startRecording,
                      onStopRecording: _stopRecording,
                      onCancelRecording: _cancelRecording,
                      onLockRecording: _lockRecording,
                      onSendVoice: _handleVoiceSend,
                      onEmojiToggle: _toggleEmoji,
                      recorderController: _recorderController,
                      recordedFilePath: _recordedFilePath,
                    ),
                    if (_showEmoji) _buildEmojiPicker(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 300.h,
      color: const Color(0xFFF2F2F2),
      child: Column(
        children: [
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
              config: Config(
                checkPlatformCompatibility: false,
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: const Color(0xFFF2F2F2),
                  columns: 7,
                  emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                ),
                categoryViewConfig: const CategoryViewConfig(
                  backgroundColor: Color(0xFFF2F2F2),
                  indicatorColor: Color(0xFF008069),
                  iconColorSelected: Color(0xFF008069),
                  iconColor: Color(0xFF8696A0),
                ),
                searchViewConfig: const SearchViewConfig(
                  backgroundColor: Color(0xFFF2F2F2),
                  buttonIconColor: Color(0xFF008069),
                ),
              ),
            ),
          ),
          // Add padding for system navigation bar (e.g. iPhone home bar or Android nav buttons)
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<dynamic> messages, String? contactImageUrl) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 40.sp, color: const Color(0xFF00A884)),
                  SizedBox(height: 12.h),
                  Text(
                    "No previous messages",
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF111B21)),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Start conversation",
                    style: TextStyle(fontSize: 14.sp, color: const Color(0xFF667781)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final Set<String> seenIds = {};
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      reverse: true,
      cacheExtent: 1000,
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildLoadMoreButton();
        }

        final messageData = messages[index];
        final isMe = _isOutgoingMessage(messageData);
        final time = _messageTime(messageData);
        final type = _getMessageType(messageData);
        final content = _getMessageContent(messageData);
        final String rawId = Helpers.getMessageId(messageData) ?? 'idx_$index';
        
        // 🛡️ Debug: Detect and log duplicate IDs being rendered
        String messageId = rawId;
        if (seenIds.contains(rawId)) {
          final text = Helpers.getNormalizedText(messageData);
          debugPrint('🚨 [UI CRITICAL] Duplicate Message ID detected in ListView: $rawId at index $index. Text: "$text". Applying safety suffix.');
          messageId = '${rawId}_dup_$index';
        }
        seenIds.add(rawId);

        bool showDateSeparator = false;
        String? dateStr;
        if (index == messages.length - 1) {
          showDateSeparator = true;
          dateStr = _messageDate(messageData);
        } else {
          final nextMessage = messages[index + 1];
          final currentDate = _messageDate(messageData);
          final nextDate = _messageDate(nextMessage);
          if (currentDate != nextDate) {
            showDateSeparator = true;
            dateStr = currentDate;
          }
        }

        bool showTail = true;
        if (index > 0) {
          final previousMessage = messages[index - 1]; // Newer message
          if (_isOutgoingMessage(previousMessage) == isMe) {
            showTail = false;
          }
        }

        return Column(
          key: ValueKey(messageId),
          children: [
            if (showDateSeparator && dateStr != null) DateSeparator(date: dateStr),
            Padding(
              padding: EdgeInsets.only(bottom: showTail ? 8.h : 2.h),
              child: VisibilityDetector(
                key: Key('msg_$messageId'),
                onVisibilityChanged: (info) {
                  if (info.visibleFraction > 0.5 && !isMe && 
                      (messageData is Map && messageData['status'] != 'read') && 
                      mounted) {
                    context.read<ContactProvider>().markContactAsRead(widget.uid, messageId: messageId);
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMessageId = (_selectedMessageId == messageId) ? null : messageId;
                    });
                  },
                  child: ChatBubble(
                    content: content,
                    time: time,
                    isMe: isMe,
                    type: type,
                    messageData: messageData,
                    imageUrl: contactImageUrl,
                    showTail: showTail,
                    isSelected: _selectedMessageId == messageId,
                    onReply: () { setState(() { _replyingTo = messageData; _focusNode.requestFocus(); }); },
                    onCopy: type == 'text' ? () => _copyMessage(content.toString()) : null,
                    onForward: () => _forwardMessage(messageData),
                    onShare: () => _shareMessage(content.toString(), type),
                    onDelete: () => _showDeleteDialog(messageData),
                    onRetry: () => _retryMessage(messageData),
                    onTapReply: (id) {
                      final targetIndex = messages.indexWhere((m) => (m['whatsapp_message_id'] ?? m['wamid'] ?? m['_uid'])?.toString() == id);
                      if (targetIndex != -1) {
                        _scrollController.animateTo(targetIndex * 60.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Consumer<ContactProvider>(
      builder: (context, provider, child) {
        // 🛡 GUARD: Don't show anything if still loading initial messages
        if (provider.isLoading && provider.messages.isEmpty) {
          return const SizedBox.shrink();
        }

        if (!provider.hasMoreChat) {
          // 🛡️ Only show "Beginning of conversation" if we have messages and explicitly reached the end
          if (provider.messages.isEmpty) return const SizedBox.shrink();
          
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                "Beginning of conversation",
                style: TextStyle(color: const Color(0xFF667781), fontSize: 12.sp, fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        if (provider.isLoadingMoreChat) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A884)),
                  ),
                  SizedBox(height: 8.h),
                  Text("Loading previous messages...", style: TextStyle(color: const Color(0xFF667781), fontSize: 12.sp)),
                ],
              ),
            ),
          );
        }

        final bool hasError = provider.errorMessage != null && provider.errorMessage!.contains("previous");

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: TextButton(
              onPressed: () => provider.loadMoreChatMessages(widget.uid),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF0F2F5),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(hasError ? Icons.refresh : Icons.arrow_upward, size: 14.sp, color: hasError ? Colors.red : const Color(0xFF008069)),
                  SizedBox(width: 8.w),
                  Text(
                    hasError ? "Failed to load. Retry?" : "Load Previous Messages",
                    style: TextStyle(color: hasError ? Colors.red : const Color(0xFF008069), fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(dynamic messageData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text("Delete message?", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete this message?", style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageData, forEveryone: false);
            },
            child: const Text("DELETE FOR ME", style: TextStyle(color: Color(0xFF008069), fontWeight: FontWeight.bold)),
          ),
          if (_isOutgoingMessage(messageData))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(messageData, forEveryone: true);
              },
              child: const Text("DELETE FOR EVERYONE", style: TextStyle(color: Color(0xFF008069), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _retryMessage(dynamic messageData) {
    final type = _getMessageType(messageData);
    final content = _getMessageContent(messageData);
    final provider = context.read<ContactProvider>();
    
    // 1. Extract message ID
    final messageId = (messageData['whatsapp_message_id'] ?? messageData['wamid'] ?? messageData['_uid'] ?? messageData['uid']).toString();
    
    // 2. Remove the failed message locally to avoid duplicates
    provider.deleteMessage(contactUid: widget.uid, messageId: messageId, forEveryone: false);
    
    // 3. Resend based on type
    if (type == 'text') {
      provider.sendMessage(contactUid: widget.uid, message: content.toString());
    } else if (type == 'image') {
      provider.sendImageMessage(contactUid: widget.uid, filePath: content.toString());
    } else if (type == 'video') {
      provider.sendVideoMessage(contactUid: widget.uid, filePath: content.toString());
    } else if (type == 'voice') {
      // Use the duration extractor from ChatBubble logic (duplicated here for scope)
      int? duration;
      if (messageData is Map) {
        duration = Helpers.toInt(messageData['duration']) ?? 
                   Helpers.toInt(Helpers.getMessageData(messageData)['media_values']?['duration']);
      }
      provider.sendVoiceMessage(contactUid: widget.uid, filePath: content.toString(), duration: duration);
    } else if (type == 'document') {
      provider.sendDocumentMessage(contactUid: widget.uid, filePath: content.toString());
    }
    
    _scrollToBottom();
  }

  void _deleteMessage(dynamic messageData, {required bool forEveryone}) {
    final messageId = (messageData['whatsapp_message_id'] ?? messageData['wamid'] ?? messageData['_uid'] ?? messageData['uid']).toString();
    // Use provider to remove message locally and handle API
    context.read<ContactProvider>().deleteMessage(
      contactUid: widget.uid,
      messageId: messageId,
      forEveryone: forEveryone,
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) => Fluttertoast.showToast(msg: "Message copied"));
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Limit Exceeded"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF008069))),
          ),
        ],
      ),
    );
  }

  void _forwardMessage(Map<String, dynamic> messageData) async {
    final List<dynamic>? selected = await context.push<List<dynamic>>('/select-contacts');
    if (selected != null && selected.isNotEmpty) {
      final provider = context.read<ContactProvider>();
      final type = _getMessageType(messageData);
      final content = _getMessageContent(messageData);
      for (var contact in selected) {
        final contactUid = (contact['_uid'] ?? contact['uid'] ?? contact['id']).toString();
        if (type == 'text') await provider.sendMessage(contactUid: contactUid, message: content.toString());
        else if (type == 'image') await provider.sendImageMessage(contactUid: contactUid, filePath: content.toString());
        else if (type == 'video') await provider.sendVideoMessage(contactUid: contactUid, filePath: content.toString());
        else if (type == 'voice') await provider.sendVoiceMessage(contactUid: contactUid, filePath: content.toString());
        else if (type == 'document') await provider.sendDocumentMessage(contactUid: contactUid, filePath: content.toString());
      }
      Fluttertoast.showToast(msg: "Forwarded");
    }
  }

  void _shareMessage(String content, String type) => Share.share(content);

  Future<void> _loadChatData() async {
    final provider = context.read<ContactProvider>();
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚀 [CHAT] NAVIGATION PATH: /chat-detail/${widget.uid}');
    debugPrint('📱 [CHAT] NEW MESSAGE FROM: ${widget.name}');
    debugPrint('🆔 [CHAT] CONTACT UID: ${widget.uid}');
    
    // 🛡️ 1. Handle Contact Details
    final bool isInList = provider.contacts.any((c) => (c['_uid'] ?? c['uid']) == widget.uid);
    debugPrint('🔍 [CHAT] CONTACT EXISTS LOCALLY: $isInList');
    
    if (!isInList) {
      setState(() => _loadingMessage = 'Loading contact...');
      debugPrint('📡 [CHAT] FETCH CONTACT API: Calling loadContactByUid for ${widget.uid}');
      
      // If UID looks like a phone number, try fetching by phone too
      bool fetched = false;
      if (RegExp(r'^\d+$').hasMatch(widget.uid)) {
        fetched = await provider.getContact(phoneNumber: widget.uid);
      } else {
        fetched = await provider.loadContactByUid(widget.uid);
      }
      
      if (!fetched && mounted) {
        debugPrint('⚠️ [CHAT] Could not fetch contact details for ${widget.uid}');
        // We continue anyway as getContactChatBoxData might still work
      }
    }

    // 🛡️ 2. Load Chat History
    setState(() => _loadingMessage = 'Loading messages...');
    debugPrint('📡 [CHAT] CHAT HISTORY API: Calling getContactChatBoxData for ${widget.uid}');
    
    final success = await provider.getContactChatBoxData(widget.uid);
    debugPrint('🏁 [CHAT] CHAT HISTORY API RESULT: $success');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    if (success) {
      debugPrint('✅ [CHAT] Chat data loaded successfully for ${widget.uid}');
      // 🛡️ Optimization: Mark contact as read immediately when entering the chat
      if (mounted) {
        provider.markContactAsRead(widget.uid);
      }
    } else if (mounted) {
      debugPrint('❌ [CHAT] Failed to load chat history for ${widget.uid}');
      if (provider.errorMessage != null) {
        debugPrint('❌ [CHAT] Error Message: ${provider.errorMessage}');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Use a post-frame callback AND a slight delay to ensure list has rebuilt with new item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            0, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOut
          );
        }
      });
      
      // Double-check after a short delay for cases where frame callback is too early
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients && _scrollController.offset > 50) {
          _scrollController.animateTo(
            0, 
            duration: const Duration(milliseconds: 200), 
            curve: Curves.easeOut
          );
        }
      });
    }
  }

  bool _isOutgoingMessage(dynamic messageData) {
    if (messageData is! Map) return false;
    final incoming = messageData['is_incoming_message'];
    if (incoming == 0 || incoming == false || incoming == '0') return true;
    if (incoming == 1 || incoming == true || incoming == '1') return false;
    final status = messageData['status']?.toString().toLowerCase();
    final direction = messageData['direction']?.toString().toLowerCase();
    return direction == 'outgoing' || status == 'sent' || status == 'delivered' || status == 'read';
  }

  String _getMessageType(dynamic messageData) {
    if (messageData is! Map) return 'text';
    
    // Check if it's a deleted message first
    if (messageData['is_deleted'] == true) return 'text';

    final mediaValues = Helpers.getMessageData(messageData)['media_values'];
    if (mediaValues is Map) {
      final type = mediaValues['type']?.toString().toLowerCase() ?? '';
      final link = mediaValues['link']?.toString() ?? '';
      
      // 🛡️ Safety: If link doesn't look like a URL or path, treat as text
      if (link.isEmpty || (!link.startsWith('http') && !link.startsWith('/') && !link.contains('cache/'))) {
        return 'text';
      }

      if (type.contains('sticker')) return 'sticker';
      if (type.contains('audio') || type.contains('voice') || type.contains('ptt')) return 'voice';
      if (type.contains('image')) return 'image';
      if (type.contains('video')) return 'video';
      if (type.contains('document') || type.contains('file') || type.contains('pdf')) return 'document';
      if (type.isNotEmpty) return type;
    }
    
    final type = (messageData['message_type'] ?? messageData['type'] ?? '').toString().toLowerCase();
    final content = _getMessageContent(messageData).toString();
    
    // 🛡️ Safety: If content doesn't look like a URL for non-text types, it's probably text
    if (type != 'text' && type.isNotEmpty) {
       if (!content.startsWith('http') && !content.startsWith('/') && !content.contains('cache/')) {
         return 'text';
       }
    }

    if (type.contains('sticker')) return 'sticker';
    if (type.contains('audio') || type.contains('voice') || type.contains('ptt')) return 'voice';
    if (type.contains('image')) return 'image';
    if (type.contains('video')) return 'video';
    if (type.contains('document') || type.contains('file') || type.contains('pdf')) return 'document';
    
    // Check by extension if type is ambiguous
    final contentLower = content.toLowerCase();
    if (contentLower.endsWith('.webp')) return 'sticker';
    if (contentLower.endsWith('.mp4') || contentLower.endsWith('.mov') || contentLower.endsWith('.mpeg') || contentLower.endsWith('.webm') || contentLower.endsWith('.mkv')) return 'video';
    if (contentLower.endsWith('.jpg') || contentLower.endsWith('.jpeg') || contentLower.endsWith('.png') || contentLower.endsWith('.gif')) return 'image';
    if (contentLower.endsWith('.aac') || contentLower.endsWith('.m4a') || contentLower.endsWith('.mp3') || contentLower.endsWith('.ogg') || contentLower.endsWith('.wav') || contentLower.endsWith('.amr')) return 'voice';

    return 'text';
  }

  dynamic _getMessageContent(dynamic messageData) {
    if (messageData is! Map) return '';
    
    final mediaValues = Helpers.getMessageData(messageData)['media_values'];
    if (mediaValues is Map && mediaValues['link'] != null) {
      final link = mediaValues['link'].toString();
      // 🛡️ Safety: Only return as link if it looks like a path or URL
      if (link.isNotEmpty && (link.startsWith('http') || link.startsWith('/') || link.contains('cache/'))) {
        return link;
      }
    }
    
    final mediaLink = messageData['media_url'] ?? 
                      messageData['link'] ?? 
                      messageData['attachment_url'] ?? 
                      messageData['attachment'] ?? 
                      messageData['video_url'] ??
                      messageData['file_url'] ??
                      messageData['uploaded_media_file_name'] ?? 
                      messageData['audio_url'];

    if (mediaLink != null && mediaLink.toString().isNotEmpty) {
      String path = mediaLink.toString();
      
      // 🛡️ Safety: If it's a full URL already, return it
      if (path.startsWith('http')) return path;
      
      // 🛡️ Safety: If it's a local file path, return it
      if (path.startsWith('/') || path.contains('cache/')) {
        if (File(path).existsSync()) return path;
      }
      
      // 🛡️ Safety check: if it looks like an error message (too many words), don't treat as URL
      if (path.split(' ').length > 2) {
        return (messageData['message'] ?? messageData['message_body'] ?? messageData['text'] ?? path).toString();
      }

      if (path.startsWith('/')) path = path.substring(1);
      if (path.startsWith('storage/')) path = path.substring(8);
      return 'https://wabchamp.com/storage/$path';
    }
    return (messageData['message'] ?? messageData['message_body'] ?? messageData['body'] ?? messageData['text'] ?? '').toString();
  }

  static final DateFormat _bubbleTimeFormat = DateFormat('hh:mm a');
  static final DateFormat _dayMonthYearFormat = DateFormat('dd MMMM yyyy');

  String _messageDate(dynamic messageData) {
    if (messageData is! Map) return '';
    final rawTime = messageData['created_at'] ?? messageData['updated_at'] ?? messageData['messaged_at'] ?? messageData['timestamp'];
    if (rawTime == null) return '';
    final dateTime = Helpers.toPKT(rawTime);
    final now = DateTime.now();
    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) return 'today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.day == yesterday.day && dateTime.month == yesterday.month && dateTime.year == yesterday.year) return 'yesterday';
    return _dayMonthYearFormat.format(dateTime).toLowerCase();
  }

  String _messageTime(dynamic messageData) {
    if (messageData is! Map) return '';
    final rawTime = messageData['created_at'] ?? messageData['updated_at'] ?? messageData['messaged_at'] ?? messageData['timestamp'];
    if (rawTime == null) return '';
    
    // Always return only time (hh:mm a) for the message bubble
    final dateTime = Helpers.toPKT(rawTime);
    return _bubbleTimeFormat.format(dateTime);
  }
}


class MediaSendPreview extends StatefulWidget {
  final String path;
  final String type;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const MediaSendPreview({
    super.key,
    required this.path,
    required this.type,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<MediaSendPreview> createState() => _MediaSendPreviewState();
}

class _MediaSendPreviewState extends State<MediaSendPreview> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Content (Image/Video)
          Positioned.fill(
            child: _buildPreview(),
          ),

          // 2. Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10.h, bottom: 10.h),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        _buildTopIconButton(Icons.close, widget.onCancel),
                        const Spacer(),
                        _buildTopIconButton(Icons.download, () {}),
                        _buildTopIconButton(Icons.hd_outlined, () {}),
                        _buildTopIconButton(Icons.sentiment_satisfied_alt_outlined, () {}),
                        _buildTopIconButton(Icons.title, () {}),
                        _buildTopIconButton(Icons.edit_outlined, () {}),
                      ],
                    ),
                  ),
                  if (widget.type == 'video') ...[
                    SizedBox(height: 10.h),
                    // Timeline Strip with Handles
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 44.h,
                          margin: EdgeInsets.symmetric(horizontal: 20.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2.r),
                            child: Row(
                              children: List.generate(10, (index) => Expanded(
                                child: Container(
                                  color: Colors.grey[800],
                                  margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                                  child: Icon(Icons.image, size: 20, color: Colors.white24),
                                ),
                              )),
                            ),
                          ),
                        ),
                        // Left Handle
                        Positioned(
                          left: 10.w,
                          top: 12.h,
                          child: Container(
                            width: 12.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        // Right Handle
                        Positioned(
                          right: 10.w,
                          top: 12.h,
                          child: Container(
                            width: 12.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          Icon(Icons.volume_up, color: Colors.white, size: 20.sp),
                          SizedBox(width: 10.w),
                          FutureBuilder<FileStat>(
                            future: File(widget.path).stat(),
                            builder: (context, snapshot) {
                              String size = "";
                              if (snapshot.hasData) size = " • ${Helpers.formatFileSize(snapshot.data!.size)}";
                              return Text(
                                "0:02$size",
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 14.sp, 
                                  fontWeight: FontWeight.w500,
                                  shadows: [Shadow(color: Colors.black45, blurRadius: 2)]
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A884),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(Icons.videocam, color: Colors.white, size: 18.sp),
                                ),
                                SizedBox(width: 4.w),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                                  child: Icon(Icons.grid_view_rounded, color: Colors.white, size: 18.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Bottom Input & Send Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, MediaQuery.of(context).padding.bottom + 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption Field
                  Container(
                    height: 50.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.circular(25.r),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_photo_alternate, color: Colors.white, size: 24.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            style: TextStyle(color: Colors.white, fontSize: 16.sp),
                            decoration: InputDecoration(
                              hintText: "Add a caption...",
                              hintStyle: TextStyle(color: Colors.white70, fontSize: 16.sp),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Footer Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: widget.onSend,
                        child: Container(
                          height: 52.w,
                          width: 52.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A884),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24.sp),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.type == 'image') {
      return InteractiveViewer(child: Image.file(File(widget.path), fit: BoxFit.contain));
    } else if (widget.type == 'video') {
      return VideoBubblePreview(
        videoUrl: widget.path, 
        isMe: true, 
        isFullWidth: true,
        onTap: () {},
      );
    } else {
      final fileName = widget.path.split('/').last;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 100.sp, color: Colors.blue),
          SizedBox(height: 20.h),
          Text(fileName, style: TextStyle(color: Colors.white, fontSize: 16.sp), textAlign: TextAlign.center),
          FutureBuilder<FileStat>(
            future: File(widget.path).stat(),
            builder: (context, snapshot) {
              if (snapshot.hasData) return Text(Helpers.formatFileSize(snapshot.data!.size), style: TextStyle(color: Colors.white70, fontSize: 14.sp));
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    }
  }
}


class ChatAppBar extends StatelessWidget {
  final String name;
  final String uid;
  final String? imageUrl;
  final VoidCallback onInfoTap;
  const ChatAppBar({super.key, required this.name, required this.uid, this.imageUrl, required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: InkWell(
        onTap: onInfoTap,
        child: Row(
          children: [
            IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: Color(0xFF008069))),
            CircleAvatar(radius: 20.r, backgroundColor: const Color(0xFFF0F2F5), backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null, child: imageUrl == null ? Icon(Icons.person, color: Colors.grey, size: 28.sp) : null),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: TextStyle(color: const Color(0xFF111B21), fontSize: 16.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('tap for info', style: TextStyle(color: const Color(0xFF667781), fontSize: 11.sp)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [IconButton(onPressed: onInfoTap, icon: const Icon(Icons.more_vert, color: Color(0xFF667781)))],
    );
  }
}


class DateSeparator extends StatelessWidget {
  final String date;
  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 24.h, bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0), 
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))
          ]
        ),
        child: Text(
          date.toUpperCase(), 
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF54656F), letterSpacing: 0.5)
        ),
      ),
    );
  }
}


class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: Container(width: 8.w, height: 8.w, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)));
  }
}


class BubbleTailPainter extends CustomPainter {
  final bool isMe;
  BubbleTailPainter({required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = isMe ? const Color(0xFFE2FFC7) : Colors.white..style = PaintingStyle.fill;
    final path = Path();
    if (isMe) { path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(0, size.height); }
    else { path.moveTo(size.width, 0); path.lineTo(0, 0); path.lineTo(size.width, size.height); }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ChatBubble extends StatelessWidget {
  final dynamic content;
  final String time;
  final bool isMe;
  final String type;
  final dynamic messageData;
  final String? imageUrl;
  final bool showTail;
  final bool isSelected;
  final VoidCallback? onReply, onCopy, onForward, onShare, onDelete, onRetry;
  final Function(String)? onTapReply;

  const ChatBubble({super.key, required this.content, required this.time, required this.isMe, required this.type, this.messageData, this.imageUrl, this.showTail = true, this.isSelected = false, this.onReply, this.onCopy, this.onForward, this.onShare, this.onDelete, this.onRetry, this.onTapReply});

  @override
  Widget build(BuildContext context) {
    final replyToMessage = messageData?['reply_to_message'];
    final bool isSticker = type == 'sticker';

    return RepaintBoundary(
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (showTail && !isSticker)
              Positioned(
                top: 0, 
                left: isMe ? null : -7.w, 
                right: isMe ? -7.w : null, 
                child: CustomPaint(painter: BubbleTailPainter(isMe: isMe), size: Size(12.w, 12.h))
              ),
            Container(
              margin: EdgeInsets.only(left: isMe ? 48.w : 0, right: isMe ? 0 : 48.w),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: isSticker ? null : BoxDecoration(
                color: isMe ? const Color(0xFFE2FFC7) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(showTail && !isMe ? 2.r : 18.r), 
                  topRight: Radius.circular(showTail && isMe ? 2.r : 18.r), 
                  bottomLeft: Radius.circular(18.r), 
                  bottomRight: Radius.circular(18.r)
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 1, offset: const Offset(0, 1))],
              ),
              child: IntrinsicWidth(
                child: Padding(
                  padding: EdgeInsets.all(isSticker ? 0 : 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (replyToMessage != null) _buildReplyPreview(replyToMessage),
                      _buildMessageContent(context),
                      if (messageData?['status'] == 'failed' && messageData?['error'] != null)
                        _buildErrorMessage(context),
                    ],
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 8.w,
                top: 8.h,
                child: _buildUniqueDropdown(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniqueDropdown(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.keyboard_arrow_down,
          size: 18.sp,
          color: const Color(0xFF667781).withValues(alpha: 0.4),
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 120.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        elevation: 4,
        offset: const Offset(0, 20),
        onSelected: (value) {
          switch (value) {
            case 'reply': onReply?.call(); break;
            case 'copy': onCopy?.call(); break;
            case 'forward': onForward?.call(); break;
            case 'share': onShare?.call(); break;
            case 'delete': onDelete?.call(); break;
          }
        },
        itemBuilder: (context) => [
          _buildPopupItem('reply', Icons.reply, 'Reply'),
          if (onCopy != null) _buildPopupItem('copy', Icons.copy, 'Copy'),
          _buildPopupItem('forward', Icons.forward, 'Forward'),
          _buildPopupItem('share', Icons.share, 'Share'),
          _buildPopupItem('delete', Icons.delete_outline, 'Delete'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String title) {
    return PopupMenuItem<String>(
      value: value,
      height: 36.h,
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: const Color(0xFF008069)),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF111B21)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final errorText = messageData['error']?.toString() ?? '';
    final is24hError = errorText == '24_hour_policy_error';
    
    return GestureDetector(
      onTap: is24hError ? () => _show24hErrorDialog(context) : null,
      child: Container(
        margin: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 4.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE), // Light red/pink
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              is24hError ? "Failed. Due to 24 hour policy." : "❗ $errorText",
              style: TextStyle(
                color: Colors.red[700], 
                fontSize: 12.sp, 
                fontWeight: FontWeight.bold,
              ),
            ),
            if (is24hError) ...[
              SizedBox(height: 4.h),
              Text(
                "Message failed to send because more than 24 hours have passed since the customer last replied to this number.",
                style: TextStyle(
                  color: Colors.red[900], 
                  fontSize: 11.sp, 
                  fontStyle: FontStyle.italic,
                  height: 1.2
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _show24hErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 24.sp),
            SizedBox(width: 10.w),
            const Text("Message Failed"),
          ],
        ),
        content: Text(
          "Message failed to send because more than 24 hours have passed since the customer last replied to this number.",
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF008069), fontWeight: FontWeight.bold)),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry!();
              },
              child: const Text("RETRY", style: TextStyle(color: Color(0xFF008069), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (type == 'voice') {
      return VoiceMessageBubble(
        audioUrl: content.toString(),
        isMe: isMe,
        duration: _extractDuration(messageData),
        senderImageUrl: imageUrl,
        time: time,
        statusIcon: isMe ? _buildStatusIcon(context, messageData) : null,
      );
    }

    final bool isMedia = type == 'image' || type == 'video' || type == 'sticker';

    return Padding(
      padding: (isMedia && type != 'sticker') ? EdgeInsets.zero : EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 4.h),
      child: Column(
        crossAxisAlignment: type == 'sticker' ? (isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start) : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContent(context),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: (isMedia && type != 'sticker') ? MainAxisAlignment.start : MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time, 
                style: TextStyle(color: const Color(0xFF667781), fontSize: 10.sp)
              ),
              if (isMe) ...[
                SizedBox(width: 4.w), 
                _buildStatusIcon(context, messageData)
              ],
            ],
          ),
        ],
      ),
    );
  }

  int? _extractDuration(dynamic messageData) {
    if (messageData is! Map) return null;

    // 1. Check direct fields
    final direct = Helpers.toInt(messageData['duration']) ?? 
                  Helpers.toInt(messageData['media_duration']) ?? 
                  Helpers.toInt(messageData['seconds']) ?? 
                  Helpers.toInt(messageData['length']) ??
                  Helpers.toInt(messageData['audio_duration']);
    if (direct != null && direct > 0) return direct;

    // 2. Check media_values in __data (Common in this app's optimistic updates)
    final mediaValues = Helpers.getMessageData(messageData)['media_values'];
    if (mediaValues is Map) {
      final nested = Helpers.toInt(mediaValues['duration']) ?? 
                    Helpers.toInt(mediaValues['media_duration']) ?? 
                    Helpers.toInt(mediaValues['seconds']) ??
                    Helpers.toInt(mediaValues['audio_duration']);
      if (nested != null && nested > 0) return nested;
    }

    // 3. Try parsing string formats like "00:05"
    final rawDuration = messageData['duration']?.toString() ?? 
                       messageData['media_duration']?.toString() ??
                       mediaValues?['duration']?.toString();
    
    if (rawDuration != null && rawDuration.contains(':')) {
      try {
        final parts = rawDuration.split(':');
        if (parts.length == 2) {
          return int.parse(parts[0]) * 60 + int.parse(parts[1]);
        } else if (parts.length == 3) {
          return int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
        }
      } catch (_) {}
    }

    return null;
  }

  Widget _buildReplyPreview(dynamic replyMessage) {
    final String rawText = (replyMessage['message'] ?? replyMessage['message_body'] ?? replyMessage['text'] ?? 'Media').toString();
    final String text = Helpers.htmlToPlainText(rawText);
    final replyToId = replyMessage['whatsapp_message_id'] ?? replyMessage['wamid'] ?? replyMessage['_uid'];
    return GestureDetector(
      onTap: () { if (onTapReply != null && replyToId != null) onTapReply!(replyToId.toString()); },
      child: Container(
        margin: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 0),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(color: isMe ? const Color(0xFFCEEAB6) : const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8.r), border: Border(left: BorderSide(color: const Color(0xFF00A884), width: 4.w))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Original Message", style: TextStyle(color: const Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 11.sp)),
            Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, dynamic messageData, {bool isOverlay = false}) {
    final status = (messageData?['status'] ?? '').toString().toLowerCase();
    final data = Helpers.getMessageData(messageData);
    final double? progress = (messageData is Map && data.isNotEmpty)
        ? (data['progress'] is num ? (data['progress'] as num).toDouble() : null)
        : null;

    if (status == 'sending' || status == 'uploading') {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 18.sp,
            height: 18.sp,
            child: CircularProgressIndicator(
              value: (progress != null && progress > 0.01) ? progress : null,
              strokeWidth: 2.0,
              color: isOverlay ? Colors.white70 : const Color(0xFF00A884),
            ),
          ),
          if (progress != null && progress > 0.01)
            Text(
              "${(progress * 100).toInt()}",
              style: TextStyle(
                fontSize: 7.sp,
                color: isOverlay ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      );
    }
    
    if (status == 'failed') {
      final errorText = messageData?['error']?.toString();
      final is24hError = errorText == '24_hour_policy_error';
      
      return GestureDetector(
        onTap: is24hError ? () => _show24hErrorDialog(context) : onRetry,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(is24hError ? Icons.error : Icons.error_outline, size: 14.sp, color: Colors.red),
            SizedBox(width: 4.w),
            Text(
              is24hError ? 'Failed' : 'Retry', 
              style: TextStyle(color: Colors.red, fontSize: 11.sp, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      );
    }

    Color iconColor = isOverlay ? Colors.white70 : Colors.grey;
    IconData iconData = Icons.done;
    if (status == 'delivered') iconData = Icons.done_all;
    else if (status == 'sent') iconData = Icons.done;
    else if (status == 'read') {
      iconData = Icons.done_all;
      iconColor = const Color(0xFF34B7F1);
    }

    return Icon(iconData, color: iconColor, size: 14.sp);
  }

  Widget _buildContent(BuildContext context) {
    if (messageData?['is_deleted'] == true) {
      return Text(
        content.toString(),
        style: TextStyle(
          color: const Color(0xFF667781),
          fontSize: 14.sp,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    switch (type) {
      case 'image': return _buildImageContent(context);
      case 'video': return _buildVideoContent(context);
      case 'sticker': return _buildStickerContent(context);
      case 'document': case 'file': return _buildFileContent();
      default:
        final rawText = content.toString();
        // Convert HTML to plain text (WhatsApp style)
        final text = Helpers.htmlToPlainText(rawText);

        final hasUrl = RegExp(r"(https?://|www\.)[^\s]+").hasMatch(text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasUrl) _buildLinkPreview(context, text),
            Linkify(
              onOpen: (link) => _onOpenLink(link.url),
              text: text,
              linkifiers: const [UrlLinkifier(), EmailLinkifier(), PhoneNumberLinkifier()],
              style: TextStyle(color: const Color(0xFF111B21), fontSize: 15.sp, height: 1.25),
              linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            ),
          ],
        );
    }
  }

  Future<void> _onOpenLink(String link) async {
    String urlString = link.trim();
    if (urlString.toLowerCase().startsWith('www.')) {
      urlString = 'https://$urlString';
    } else if (RegExp(r"^\+?[0-9]{7,15}$").hasMatch(urlString)) {
      urlString = 'tel:$urlString';
    }
    
    final Uri url = Uri.parse(urlString);
    try {
      bool launched = false;
      if (await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      
      if (!launched) {
        // Try launching without externalApplication for some schemes if it fails
        launched = await launchUrl(url);
      }

      if (!launched) {
        Fluttertoast.showToast(msg: "Could not open link");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Invalid link");
    }
  }

  Widget _buildLinkPreview(BuildContext context, String text) {
    final match = RegExp(r"(https?://|www\.)[^\s]+").firstMatch(text);
    if (match == null) return const SizedBox.shrink();

    String url = match.group(0)!;
    if (url.startsWith('www.')) {
      url = 'https://$url';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: AnyLinkPreview(
        link: url,
        displayDirection: UIDirection.uiDirectionHorizontal,
        showMultimedia: true,
        bodyMaxLines: 2,
        bodyTextOverflow: TextOverflow.ellipsis,
        titleStyle: TextStyle(
          color: const Color(0xFF111B21),
          fontWeight: FontWeight.bold,
          fontSize: 13.sp,
        ),
        bodyStyle: TextStyle(color: const Color(0xFF667781), fontSize: 11.sp),
        placeholderWidget: Container(
          height: 60.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: const SizedBox.shrink(),
        cache: const Duration(days: 7),
        backgroundColor: isMe ? const Color(0xFFD9FDD3) : const Color(0xFFF0F2F5),
        borderRadius: 8.r,
        onTap: () => _onOpenLink(url),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final String url = content.toString();
    final bool isLocal = url.startsWith('/') || url.contains('cache/');
    
    return GestureDetector(
      onTap: () => _openFullscreenMedia(context, url, 'image'),
      child: Container(
        width: 210.w,
        height: 160.h,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: isMe ? const Color(0xFFC3E7B2) : Colors.black12, width: 1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            isLocal
                ? Image.file(File(url), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white54),
                  ),
            if (!isLocal && !url.startsWith('http')) 
              const Icon(Icons.download, color: Colors.white70, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    final String url = content.toString();
    final int? duration = _extractDuration(messageData);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isMe ? const Color(0xFFC3E7B2) : Colors.black12, width: 1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: VideoBubblePreview(
        videoUrl: url,
        isMe: isMe,
        width: 210.w,
        height: 160.h,
        duration: duration,
        onTap: () => _openFullscreenMedia(context, url, 'video'),
      ),
    );
  }

  Widget _buildStickerContent(BuildContext context) {
    final String url = content.toString();
    final bool isLocal = url.startsWith('/') || url.contains('cache/');
    
    return Container(
      width: 160.w,
      height: 160.w,
      constraints: BoxConstraints(
        maxWidth: 180.w,
        maxHeight: 180.w,
      ),
      child: isLocal
          ? Image.file(
              File(url), 
              fit: BoxFit.contain, 
              width: double.infinity, 
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _buildStickerError(),
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A884)),
              ),
              errorWidget: (context, url, error) => _buildStickerError(),
            ),
    );
  }

  Widget _buildStickerError() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey, size: 24.sp),
            SizedBox(height: 4.h),
            Text("Retry", style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent() {
    final String path = content.toString();
    final String fileName = path.split('/').last;
    final String ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    
    IconData iconData = Icons.insert_drive_file;
    Color iconColor = Colors.grey;
    
    if (ext == 'pdf') { iconData = Icons.picture_as_pdf; iconColor = Colors.red; }
    else if (['doc', 'docx'].contains(ext)) { iconData = Icons.description; iconColor = Colors.blue; }
    else if (['xls', 'xlsx'].contains(ext)) { iconData = Icons.table_chart; iconColor = Colors.green; }
    else if (['ppt', 'pptx'].contains(ext)) { iconData = Icons.slideshow; iconColor = Colors.orange; }
    else if (ext == 'zip') { iconData = Icons.archive; iconColor = Colors.brown; }
    else if (ext == 'txt') { iconData = Icons.text_snippet; iconColor = Colors.blueGrey; }

    return StatefulBuilder(
      builder: (context, setState) {
        double downloadProgress = 0;
        bool isDownloading = false;

        return GestureDetector(
          onTap: isDownloading ? null : () async {
            setState(() => isDownloading = true);
            await Helpers.openFile(
              urlOrPath: path,
              fileName: fileName,
              onProgress: (p) => setState(() => downloadProgress = p),
            );
            if (context.mounted) setState(() => isDownloading = false);
          },
          child: Container(
            width: 220.w,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFC3E7B2) : const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(iconData, color: iconColor, size: 30.sp),
                    if (isDownloading)
                      SizedBox(
                        width: 30.sp,
                        height: 30.sp,
                        child: CircularProgressIndicator(
                          value: downloadProgress > 0 ? downloadProgress : null,
                          strokeWidth: 2,
                          color: const Color(0xFF00A884),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isDownloading 
                          ? "${(downloadProgress * 100).toInt()}%" 
                          : ext.toUpperCase(),
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, color: Colors.grey, size: 20.sp),
              ],
            ),
          ),
        );
      }
    );
  }

  void _openFullscreenMedia(BuildContext context, String url, String type) async {
    if (type == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenVideoPlayer(videoUrl: url),
        ),
      );
      return;
    }

    if (type == 'image') {
      showDialog(
        context: context,
        builder: (context) => _ImageGalleryViewer(url: url),
      );
      return;
    }
    
    // Fallback for other types
    Helpers.openFile(urlOrPath: url);
  }
}


class _ImageGalleryViewer extends StatefulWidget {
  final String url;
  const _ImageGalleryViewer({required this.url});

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
  bool _isDownloading = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    final bool isLocal = widget.url.startsWith('/') || widget.url.contains('cache/');
    
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: isLocal 
                ? Image.file(File(widget.url)) 
                : CachedNetworkImage(
                    imageUrl: widget.url, 
                    placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFF00A884)),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  ),
            ),
          ),
          Positioned(
            top: 40.h, 
            left: 10.w,
            right: 10.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30), 
                  onPressed: () => Navigator.pop(context)
                ),
                IconButton(
                  icon: _isDownloading 
                    ? SizedBox(
                        width: 24.w, 
                        height: 24.w, 
                        child: CircularProgressIndicator(
                          value: _progress > 0 ? _progress : null, 
                          strokeWidth: 2, 
                          color: Colors.white
                        )
                      )
                    : const Icon(Icons.download, color: Colors.white, size: 30),
                  onPressed: _isDownloading ? null : () async {
                    setState(() => _isDownloading = true);
                    await Helpers.openFile(
                      urlOrPath: widget.url,
                      onProgress: (p) => setState(() => _progress = p),
                    );
                    if (mounted) setState(() => _isDownloading = false);
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


class ChatCountdownTimer extends StatefulWidget {
  const ChatCountdownTimer({super.key});

  @override
  State<ChatCountdownTimer> createState() => _ChatCountdownTimerState();
}

class _ChatCountdownTimerState extends State<ChatCountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      final provider = context.read<ContactProvider>();
      final lastIncoming = provider.getLastIncomingMessageTime();
      if (lastIncoming != null) {
        final expiry = lastIncoming.add(const Duration(hours: 24));
        final now = Helpers.toUtc(null);
        final diff = expiry.difference(now);
        
        if (diff.inSeconds != _remaining.inSeconds) {
          setState(() {
            _remaining = diff;
          });
        }
      } else if (_remaining != Duration.zero) {
        setState(() {
          _remaining = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = _remaining.isNegative || _remaining == Duration.zero;
    final String formattedTime = Helpers.format24hCountdown(_remaining);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFFFEBEE) : const Color(0xFFD9FDD3), 
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExpired ? Icons.error_outline : Icons.history, 
            size: 14.sp, 
            color: isExpired ? Colors.red[700] : const Color(0xFF008069)
          ),
          SizedBox(width: 8.w),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF111B21)),
              children: [
                TextSpan(text: isExpired ? "24-hour window " : "24-hour window ends in "),
                TextSpan(
                  text: isExpired ? "expired" : "$formattedTime left",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class PhoneNumberLinkifier extends Linkifier {
  const PhoneNumberLinkifier();

  @override
  List<LinkifyElement> parse(List<LinkifyElement> elements, LinkifyOptions options) {
    final list = <LinkifyElement>[];
    final regex = RegExp(r"\+?[0-9]{7,15}");

    for (var element in elements) {
      if (element is TextElement) {
        final matches = regex.allMatches(element.text);
        if (matches.isEmpty) {
          list.add(element);
          continue;
        }

        int lastIndex = 0;
        for (var match in matches) {
          if (match.start > lastIndex) {
            list.add(TextElement(element.text.substring(lastIndex, match.start)));
          }
          list.add(LinkableElement(match.group(0)!, "tel:${match.group(0)}"));
          lastIndex = match.end;
        }

        if (lastIndex < element.text.length) {
          list.add(TextElement(element.text.substring(lastIndex)));
        }
      } else {
        list.add(element);
      }
    }
    return list;
  }
}


class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTyping;
  final bool isSending;
  final bool showEmoji;
  final RecordingState recordingState;
  final int recordDuration;
  final VoidCallback onAttachment, onCamera, onSend, onCancelReply, onStartRecording, onCancelRecording, onLockRecording, onSendVoice, onEmojiToggle;
  final Function({bool sendImmediately}) onStopRecording;
  final Map<String, dynamic>? replyingTo;
  final RecorderController recorderController;
  final String? recordedFilePath;

  const ChatInputBar({
    super.key, 
    required this.controller, 
    required this.focusNode, 
    required this.isTyping, 
    this.isSending = false,
    required this.showEmoji,
    required this.onAttachment, 
    required this.onCamera, 
    required this.onSend, 
    this.replyingTo, 
    required this.onCancelReply, 
    required this.recordingState, 
    required this.recordDuration, 
    required this.onStartRecording, 
    required this.onStopRecording, 
    required this.onCancelRecording,
    required this.onLockRecording,
    required this.onSendVoice,
    required this.onEmojiToggle,
    required this.recorderController,
    this.recordedFilePath,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  double _dragOffset = 0;
  AudioPlayer? _previewPlayer;
  bool _isPlayingPreview = false;
  Duration _previewPosition = Duration.zero;
  Duration _previewDuration = Duration.zero;

  @override
  void dispose() {
    _previewPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initPreview() async {
    if (widget.recordedFilePath == null) return;
    try {
      setState(() {
        _previewPosition = Duration.zero;
        _previewDuration = Duration.zero;
      });
      _previewPlayer?.dispose();
      _previewPlayer = AudioPlayer();
      await _previewPlayer!.setFilePath(widget.recordedFilePath!);
      _previewPlayer!.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _previewDuration = d);
      });
      _previewPlayer!.positionStream.listen((p) {
        if (mounted) setState(() => _previewPosition = p);
      });
      _previewPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlayingPreview = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _previewPlayer!.pause();
              _previewPlayer!.seek(Duration.zero);
            }
          });
        }
      });
    } catch (e) {
      debugPrint("❌ [AUDIO_PREVIEW] Error initializing preview player: $e");
    }
  }

  void _togglePreview() {
    if (_isPlayingPreview) {
      _previewPlayer?.pause();
    } else {
      _previewPlayer?.play();
    }
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recordingState == RecordingState.preview && oldWidget.recordingState != RecordingState.preview) {
      _initPreview();
    }
    if (widget.recordingState == RecordingState.idle) {
      _previewPlayer?.stop();
      _dragOffset = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recordingState == RecordingState.preview) {
      return _buildVoicePreview();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, widget.showEmoji ? 4.h : 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              // The single pill-shaped background for the entire input area
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.replyingTo != null) _buildReplyPreview(),
                  if (widget.recordingState == RecordingState.recording || widget.recordingState == RecordingState.locked)
                    _buildRecordingUI()
                  else
                    _buildTextInputUI(),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _buildActionCircle(),
        ],
      ),
    );
  }

  Widget _buildTextInputUI() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: widget.onEmojiToggle,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          constraints: const BoxConstraints(),
          icon: Icon(
            widget.showEmoji ? Icons.keyboard : Icons.sentiment_satisfied_alt_outlined,
            color: const Color(0xFF8696A0),
            size: 26.sp,
          ),
        ),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            maxLines: 6,
            minLines: 1,
            cursorColor: const Color(0xFF00A884),
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(fontSize: 17.sp, color: const Color(0xFF111B21), height: 1.2),
            decoration: InputDecoration(
              hintText: 'Message',
              hintStyle: TextStyle(color: const Color(0xFF8696A0), fontSize: 17.sp),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              filled: false,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.onAttachment,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          constraints: const BoxConstraints(),
          icon: Transform.rotate(
            angle: -0.7,
            child: Icon(Icons.attach_file, color: const Color(0xFF8696A0), size: 24.sp),
          ),
        ),
        if (!widget.isTyping)
          IconButton(
            onPressed: widget.onCamera,
            padding: EdgeInsets.only(right: 12.w, left: 4.w),
            constraints: const BoxConstraints(),
            icon: Icon(Icons.camera_alt, color: const Color(0xFF8696A0), size: 24.sp),
          ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    final isLocked = widget.recordingState == RecordingState.locked;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🗑️ Delete Button
          IconButton(
            onPressed: widget.onCancelRecording, 
            icon: Icon(Icons.delete, color: isLocked ? const Color(0xFF8696A0) : Colors.red, size: 24.sp)
          ),
          
          // 🔴 Recording Indicator & Timer
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isLocked) ...[
                const _BlinkingDot(),
                SizedBox(width: 4.w),
              ],
              Text(
                Helpers.formatDuration(widget.recordDuration), 
                style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.w500)
              ),
            ],
          ),
          
          SizedBox(width: 8.w),
          
          // 📊 Waveform
          Expanded(
            child: AudioWaveforms(
              size: Size(double.infinity, 30.h),
              recorderController: widget.recorderController,
              enableGesture: false,
              waveStyle: WaveStyle(
                waveColor: const Color(0xFF00A884),
                spacing: 6.0,
                showMiddleLine: false,
                extendWaveform: true,
              ),
            ),
          ),
          
          // 🔒 Stop Button (Only when locked)
          if (isLocked)
            IconButton(
              onPressed: () => widget.onStopRecording(sendImmediately: false),
              icon: Icon(Icons.stop_circle_outlined, color: Colors.red, size: 28.sp)
            )
          else
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Row(
                children: [
                  Text("Slide to cancel", style: TextStyle(color: const Color(0xFF8696A0), fontSize: 14.sp)),
                  const Icon(Icons.keyboard_arrow_left, color: Color(0xFF8696A0), size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoicePreview() {
    final bool showPosition = _isPlayingPreview || _previewPosition.inMilliseconds > 0;
    final int displaySeconds = showPosition 
        ? _previewPosition.inSeconds 
        : (_previewDuration.inSeconds > 0 ? _previewDuration.inSeconds : widget.recordDuration);

    return Container(
      margin: widget.showEmoji ? EdgeInsets.fromLTRB(8.w, 8.w, 8.w, 4.w) : EdgeInsets.all(8.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
      ),
      child: Row(
        children: [
          IconButton(onPressed: widget.onCancelRecording, icon: const Icon(Icons.delete, color: Color(0xFF8696A0))),
          IconButton(
            onPressed: _togglePreview, 
            icon: Icon(_isPlayingPreview ? Icons.pause : Icons.play_arrow, color: const Color(0xFF8696A0))
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.h,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                activeTrackColor: const Color(0xFF34B7F1),
                inactiveTrackColor: Colors.grey[300],
                thumbColor: const Color(0xFF34B7F1),
              ),
              child: Slider(
                value: _previewPosition.inMilliseconds.toDouble().clamp(0, _previewDuration.inMilliseconds.toDouble() > 0 ? _previewDuration.inMilliseconds.toDouble() : widget.recordDuration * 1000.0),
                max: _previewDuration.inMilliseconds.toDouble() > 0 
                    ? _previewDuration.inMilliseconds.toDouble() 
                    : (widget.recordDuration > 0 ? widget.recordDuration * 1000.0 : 1.0),
                onChanged: (v) => _previewPlayer?.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
          ),
          Text(
            Helpers.formatDuration(displaySeconds), 
            style: TextStyle(fontSize: 12.sp, color: Colors.grey)
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: widget.isSending ? null : widget.onSendVoice,
            child: Container(
              height: 40.w,
              width: 40.w,
              decoration: BoxDecoration(
                color: widget.isSending ? Colors.grey : const Color(0xFF00A884), 
                shape: BoxShape.circle
              ),
              child: widget.isSending 
                ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle() {
    final isRecording = widget.recordingState == RecordingState.recording;
    final isLocked = widget.recordingState == RecordingState.locked;
    
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (isRecording)
          Positioned(
            bottom: 60.h + _dragOffset.clamp(0, 100).h,
            child: Column(
              children: [
                Icon(Icons.lock_outline, color: const Color(0xFF00A884), size: 20.sp),
                SizedBox(height: 4.h),
                const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
              ],
            ),
          ),
        GestureDetector(
          onTap: () {
            if (widget.isSending) return;
            if (widget.isTyping) {
              widget.onSend();
            } else if (isRecording) {
              setState(() => _dragOffset = 0);
              widget.onStopRecording(sendImmediately: false);
            } else if (isLocked) {
              widget.onSendVoice();
            } else {
              widget.onStartRecording();
            }
          },
          onVerticalDragUpdate: (details) {
            if (isRecording && !widget.isSending) {
              setState(() {
                _dragOffset -= details.delta.dy;
                if (_dragOffset > 60) {
                  _dragOffset = 0;
                  widget.onLockRecording();
                }
              });
            }
          },
          onHorizontalDragUpdate: (details) {
            if (isRecording && details.delta.dx < -10 && !widget.isSending) {
              _dragOffset = 0;
              widget.onCancelRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 50.w,
            width: 50.w,
            margin: EdgeInsets.only(bottom: isRecording ? _dragOffset.clamp(0, 10).h : 0),
            decoration: BoxDecoration(
              color: widget.isSending ? Colors.grey : const Color(0xFF111B21),
              shape: BoxShape.circle
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: widget.isSending && widget.isTyping
                ? SizedBox(key: const ValueKey('loading'), width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(
                    widget.isTyping ? Icons.send : (isRecording ? Icons.stop : (isLocked ? Icons.send : Icons.mic)), 
                    color: Colors.white, 
                    size: 24.sp,
                    key: ValueKey(widget.isTyping ? 'send' : (isRecording ? 'stop' : (isLocked ? 'send_voice' : 'mic'))),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    final message = widget.replyingTo?['message'] ?? widget.replyingTo?['message_body'] ?? widget.replyingTo?['text'] ?? 'Media';
    return Container(
      margin: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 4.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5), 
        borderRadius: BorderRadius.circular(12.r), 
        border: Border(left: BorderSide(color: const Color(0xFF00A884), width: 4.w))
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text("Replying to", style: TextStyle(color: const Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 11.sp)), 
                Text(message.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xFF54656F), fontSize: 14.sp))
              ]
            )
          ),
          IconButton(
            onPressed: widget.onCancelReply, 
            icon: Icon(Icons.close, size: 18.sp, color: const Color(0xFF8696A0)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ChatStateData {
  final List<dynamic> messages;
  final bool isLoading;
  final String? errorMessage;

  _ChatStateData({
    required this.messages,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ChatStateData &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          listEquals(messages, other.messages);

  @override
  int get hashCode =>
      Object.hash(messages, isLoading, errorMessage);
}

