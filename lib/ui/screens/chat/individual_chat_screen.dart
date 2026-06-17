import 'dart:async';
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
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../core/utils/helpers.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';
import 'widgets/voice_message_bubble.dart';
import 'widgets/video_player_widget.dart';

enum RecordingState { idle, recording, locked, preview }

class IndividualChatScreen extends StatefulWidget {
  final String uid;
  final String name;
  const IndividualChatScreen({super.key, required this.uid, required this.name});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  final FocusNode _focusNode = FocusNode();
  
  Timer? _pollingTimer;
  bool _isPolling = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatData();
      _startPolling();
    });
  }

  String _sanitizeText(String? text) {
    if (text == null) return '';
    return Helpers.htmlToPlainText(Helpers.sanitizeString(text)).trim();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted && !_isPolling) {
        _isPolling = true;
        await context
            .read<ContactProvider>()
            .getContactChatBoxData(widget.uid, showLoading: false);
        _isPolling = false;
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _recorderController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // 🛡️ Request microphone permission explicitly using permission_handler
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        Fluttertoast.showToast(msg: "Microphone permission denied");
        return;
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      _recordedFilePath = path;
      
      const config = RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100);
      await _audioRecorder.start(config, path: path);
      
      // 🛡️ Waveform recording can sometimes fail due to plugin linking issues
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
      debugPrint("❌ [RECORD] Start recording error: $e");
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
    context.read<ContactProvider>().sendVoiceMessage(
          contactUid: widget.uid,
          filePath: path,
          duration: _recordDuration,
        );
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
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) _sendImage(photo.path);
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
                    Navigator.pop(context, 'video:${video.path}');
                  }
                }),
                _buildAttachmentOption(Icons.insert_drive_file, "Document", Colors.blue, () async {
                  FilePickerResult? res = await FilePicker.platform.pickFiles();
                  if (res != null && mounted) {
                    Navigator.pop(context, 'file:${res.files.single.path}');
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
        _sendImage(result.substring(6));
      } else if (result.startsWith('video:')) {
        _sendVideo(result.substring(6));
      } else if (result.startsWith('file:')) {
        _sendDocument(result.substring(5));
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
    context.read<ContactProvider>().sendImageMessage(contactUid: widget.uid, filePath: path);
    _scrollToBottom();
  }

  void _sendVideo(String path) {
    context.read<ContactProvider>().sendVideoMessage(contactUid: widget.uid, filePath: path);
    _scrollToBottom();
  }

  void _sendDocument(String path) {
    context.read<ContactProvider>().sendDocumentMessage(contactUid: widget.uid, filePath: path);
    _scrollToBottom();
  }

  void _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      debugPrint('🖱️ [UI] Send button tapped');
      final provider = context.read<ContactProvider>();
      final replyId = _replyingTo?['whatsapp_message_id'] ?? _replyingTo?['wamid'];
      
      // Clear input and reply status immediately for responsiveness
      _messageController.clear();
      if (_replyingTo != null) {
        setState(() { _replyingTo = null; });
      }
      
      // Call provider to send message (it handles optimistic update and notifyListeners)
      provider.sendMessage(
        contactUid: widget.uid, 
        message: text, 
        replyToMessageId: replyId?.toString()
      );
      
      // Force scroll to bottom to show the new message
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
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Consumer<ContactProvider>(
          builder: (context, provider, child) {
            // OPTIMIZED: Cache the contact lookup
            final contact = provider.selectedContact != null && 
                           (provider.selectedContact!['_uid'] ?? provider.selectedContact!['uid']) == widget.uid
                ? provider.selectedContact!
                : provider.contacts.firstWhere(
                    (c) => (c['_uid'] ?? c['uid']) == widget.uid, 
                    orElse: () => <String, dynamic>{}
                  );

            final name = contact['full_name'] ?? contact['first_name'] ?? widget.name;
            final imageUrl = contact['profile_image'] ?? contact['image_url'];
            return ChatAppBar(name: _sanitizeText(name), uid: widget.uid, imageUrl: imageUrl, onInfoTap: _showContactInfo);
          },
        ),
      ),
      body: GestureDetector(
        onTap: () { if (_selectedMessageId != null) setState(() => _selectedMessageId = null); },
        child: Stack(
          children: [
            Opacity(
              opacity: 0.08,
              child: CachedNetworkImage(
                imageUrl: 'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                useOldImageOnUrlChange: true,
              ),
            ),
            SafeArea(
              bottom: true,
              child: Column(
                children: [
                  Expanded(
                    child: Consumer<ContactProvider>(
                      builder: (context, provider, child) {
                        debugPrint('🎨 [UI] Rebuilding chat list. Total messages: ${provider.messages.length}');
                        if (provider.isLoading && provider.messages.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        // Optimized: Pass message list to builder
                        return _buildMessagesList(provider.messages, null);
                      },
                    ),
                  ),
                  ChatInputBar(
                    controller: _messageController,
                    focusNode: _focusNode,
                    isTyping: _isTyping,
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
                    recorderController: _recorderController,
                    recordedFilePath: _recordedFilePath,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<dynamic> messages, String? contactImageUrl) {
    if (messages.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12.r)),
          child: const Text("No messages yet. Say hi!"),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final messageData = messages[index];
        final isMe = _isOutgoingMessage(messageData);
        final time = _messageTime(messageData);
        final type = _getMessageType(messageData);
        final content = _getMessageContent(messageData);
        final messageId = (messageData['whatsapp_message_id'] ?? messageData['wamid'] ?? messageData['_uid'] ?? index).toString();

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
          final previousMessage = messages[index - 1];
          if (_isOutgoingMessage(previousMessage) == isMe) showTail = false;
        }

        return Column(
          key: ValueKey(messageId),
          children: [
            if (showDateSeparator && dateStr != null) DateSeparator(date: dateStr),
            GestureDetector(
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
                onTapReply: (id) {
                  final targetIndex = messages.indexWhere((m) => (m['whatsapp_message_id'] ?? m['wamid'] ?? m['_uid'])?.toString() == id);
                  if (targetIndex != -1) {
                    _scrollController.animateTo(targetIndex * 60.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _messageDate(dynamic messageData) {
    if (messageData is! Map) return '';
    final rawTime = messageData['created_at'] ?? messageData['updated_at'] ?? messageData['messaged_at'] ?? messageData['timestamp'];
    if (rawTime == null) return '';
    final dateTime = Helpers.toPKT(rawTime);
    final now = DateTime.now();
    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) return 'today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.day == yesterday.day && dateTime.month == yesterday.month && dateTime.year == yesterday.year) return 'yesterday';
    return DateFormat('dd MMMM yyyy').format(dateTime).toLowerCase();
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
    await provider.getContactChatBoxData(widget.uid);
    if (provider.messages.isNotEmpty && mounted) {
      provider.getContactChatBoxData(widget.uid, showLoading: false, refresh: true);
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
    final mediaValues = messageData['__data']?['media_values'];
    if (mediaValues is Map) {
      final type = mediaValues['type']?.toString().toLowerCase() ?? '';
      if (type.contains('audio') || type.contains('voice') || type.contains('ptt')) return 'voice';
      if (type.contains('image')) return 'image';
      if (type.contains('video')) return 'video';
      if (type.contains('document') || type.contains('file') || type.contains('pdf')) return 'document';
      if (type.isNotEmpty) return type;
    }
    final type = (messageData['message_type'] ?? messageData['type'] ?? '').toString().toLowerCase();
    if (type.contains('audio') || type.contains('voice') || type.contains('ptt')) return 'voice';
    if (type.contains('image')) return 'image';
    if (type.contains('video')) return 'video';
    if (type.contains('document') || type.contains('file') || type.contains('pdf')) return 'document';
    
    // Check by extension if type is ambiguous
    final content = _getMessageContent(messageData).toString().toLowerCase();
    if (content.endsWith('.mp4') || content.endsWith('.mov') || content.endsWith('.mpeg') || content.endsWith('.webm') || content.endsWith('.mkv')) return 'video';
    if (content.endsWith('.jpg') || content.endsWith('.jpeg') || content.endsWith('.png') || content.endsWith('.gif') || content.endsWith('.webp')) return 'image';

    return 'text';
  }

  dynamic _getMessageContent(dynamic messageData) {
    if (messageData is! Map) return '';
    final mediaValues = messageData['__data']?['media_values'];
    if (mediaValues is Map && mediaValues['link'] != null) {
      final link = mediaValues['link'].toString();
      if (link.isNotEmpty) return link;
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
      if (path.startsWith('/') || path.contains('cache/')) {
        if (File(path).existsSync()) return path;
      }
      if (path.startsWith('http')) return path;
      if (path.startsWith('/')) path = path.substring(1);
      if (path.startsWith('storage/')) path = path.substring(8);
      return 'https://wabchamp.com/storage/$path';
    }
    return (messageData['message'] ?? messageData['message_body'] ?? messageData['body'] ?? messageData['text'] ?? '').toString();
  }

  String _messageTime(dynamic messageData) {
    if (messageData is! Map) return '';
    final rawTime = messageData['created_at'] ?? messageData['updated_at'] ?? messageData['messaged_at'] ?? messageData['timestamp'];
    return rawTime == null ? '' : Helpers.formatTimestamp(rawTime);
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8.r)),
      child: Text(date.toUpperCase(), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF54656F))),
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
  final VoidCallback? onReply, onCopy, onForward, onShare, onDelete;
  final Function(String)? onTapReply;

  const ChatBubble({super.key, required this.content, required this.time, required this.isMe, required this.type, this.messageData, this.imageUrl, this.showTail = true, this.isSelected = false, this.onReply, this.onCopy, this.onForward, this.onShare, this.onDelete, this.onTapReply});

  @override
  Widget build(BuildContext context) {
    final replyToMessage = messageData?['reply_to_message'];
    return Stack(
      children: [
        if (showTail)
          Positioned(top: 0, left: isMe ? null : -8.w, right: isMe ? -8.w : null, child: CustomPaint(painter: BubbleTailPainter(isMe: isMe), size: Size(15.w, 15.h))),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(bottom: showTail ? 4.h : 2.h, top: 2.h, left: isMe ? 64.w : 4.w, right: isMe ? 4.w : 64.w),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFE2FFC7) : Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(showTail && !isMe ? 0 : 12.r), topRight: Radius.circular(showTail && isMe ? 0 : 12.r), bottomLeft: Radius.circular(12.r), bottomRight: Radius.circular(12.r)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 1, offset: const Offset(0, 1))],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyToMessage != null) _buildReplyPreview(replyToMessage),
                    _buildMessageContent(context),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    right: 2.w,
                    top: 2.h,
                    child: _buildUniqueDropdown(context),
                  ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildMessageContent(BuildContext context) {
    if (type == 'voice') {
      return VoiceMessageBubble(
        audioUrl: content.toString(),
        isMe: isMe,
        duration: Helpers.toInt(messageData?['duration']) ?? Helpers.toInt(messageData?['__data']?['media_values']?['duration']),
        senderImageUrl: imageUrl,
        time: time,
        statusIcon: isMe ? _buildStatusIcon() : null,
      );
    }

    return Padding(
      padding: type == 'image' || type == 'video' ? EdgeInsets.all(4.w) : EdgeInsets.fromLTRB(10.w, 6.h, 12.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(right: isSelected ? 18.w : 0),
            child: _buildContent(context),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(time, style: TextStyle(color: const Color(0xFF667781), fontSize: 10.sp)),
              if (isMe) ...[SizedBox(width: 4.w), _buildStatusIcon()],
            ],
          ),
        ],
      ),
    );
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

  Widget _buildStatusIcon() {
    final status = (messageData?['status'] ?? '').toString().toLowerCase();
    if (status == 'sending') return Icon(Icons.access_time, size: 10.sp, color: Colors.grey);
    Color iconColor = Colors.grey; IconData iconData = Icons.done;
    if (status == 'delivered') iconData = Icons.done_all;
    else if (status == 'sent') iconData = Icons.done;
    else if (status == 'read') { iconData = Icons.done_all; iconColor = const Color(0xFF34B7F1); }
    else if (status == 'failed') return Icon(Icons.error_outline, size: 12.sp, color: Colors.red);
    return Icon(iconData, color: iconColor, size: 13.sp);
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
      child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: isLocal
              ? Image.file(File(url), height: 150.h, width: 200.w, fit: BoxFit.cover)
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  height: 150.h,
                  width: 200.w,
                  placeholder: (context, url) => Container(
                    height: 150.h,
                    width: 200.w,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    final String url = content.toString();
    return VideoBubblePreview(
      videoUrl: url,
      isMe: isMe,
      onTap: () => _openFullscreenMedia(context, url, 'video'),
    );
  }

  Widget _buildFileContent() => Container(width: 200.w, padding: EdgeInsets.all(8.w), decoration: BoxDecoration(color: isMe ? const Color(0xFFC3E7B2) : const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(8.r)), child: Row(children: [const Icon(Icons.insert_drive_file, color: Colors.grey), SizedBox(width: 8.w), Expanded(child: Text(content.toString().split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp))), const Icon(Icons.download, color: Colors.grey, size: 20)]));

  void _openFullscreenMedia(BuildContext context, String url, String type) {
    if (type == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenVideoPlayer(videoUrl: url),
        ),
      );
      return;
    }
    final bool isLocal = url.startsWith('/') || url.contains('cache/');
    showDialog(
        context: context,
        builder: (context) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Stack(children: [
              Center(child: InteractiveViewer(child: isLocal ? Image.file(File(url)) : CachedNetworkImage(imageUrl: url, placeholder: (context, url) => const CircularProgressIndicator(), errorWidget: (context, url, error) => const Icon(Icons.error)))),
              Positioned(top: 40.h, right: 20.w, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)))
            ])));
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
  final RecordingState recordingState;
  final int recordDuration;
  final VoidCallback onAttachment, onCamera, onSend, onCancelReply, onStartRecording, onCancelRecording, onLockRecording, onSendVoice;
  final Function({bool sendImmediately}) onStopRecording;
  final Map<String, dynamic>? replyingTo;
  final RecorderController recorderController;
  final String? recordedFilePath;

  const ChatInputBar({
    super.key, 
    required this.controller, 
    required this.focusNode, 
    required this.isTyping, 
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: 52.h),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(32.r), 
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
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
        ),
      ],
    );
  }

  Widget _buildTextInputUI() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF8696A0))),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: 2.h), 
            child: TextField(
              controller: widget.controller, 
              focusNode: widget.focusNode, 
              maxLines: 5, 
              minLines: 1, 
              cursorColor: const Color(0xFF00A884), 
              style: TextStyle(fontSize: 17.sp, color: const Color(0xFF111B21)), 
              decoration: InputDecoration(
                hintText: 'Message', 
                hintStyle: TextStyle(color: const Color(0xFF8696A0), fontSize: 17.sp), 
                border: InputBorder.none, 
                isDense: true, 
                contentPadding: EdgeInsets.symmetric(vertical: 12.h)
              )
            )
          )
        ),
        IconButton(onPressed: widget.onAttachment, icon: Transform.rotate(angle: -0.7, child: const Icon(Icons.attach_file, color: Color(0xFF8696A0)))),
        if (!widget.isTyping)
          IconButton(onPressed: widget.onCamera, icon: const Icon(Icons.camera_alt, color: Color(0xFF8696A0))),
      ],
    );
  }

  Widget _buildRecordingUI() {
    final isLocked = widget.recordingState == RecordingState.locked;
    return Container(
      height: 52.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
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
              padding: EdgeInsets.only(right: 8.w),
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
      margin: EdgeInsets.all(8.w),
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
            onTap: widget.onSendVoice,
            child: Container(
              height: 40.w,
              width: 40.w,
              decoration: const BoxDecoration(color: Color(0xFF00A884), shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
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
            if (isRecording) {
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
            if (isRecording && details.delta.dx < -10) {
              _dragOffset = 0;
              widget.onCancelRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 52.w,
            width: 52.w,
            margin: EdgeInsets.only(bottom: isRecording ? _dragOffset.clamp(0, 10).h : 0),
            decoration: const BoxDecoration(color: Color(0xFF00A884), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(
              widget.isTyping ? Icons.send : (isRecording ? Icons.stop : (isLocked ? Icons.send : Icons.mic)), 
              color: Colors.white, 
              size: 24.sp
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    final message = widget.replyingTo?['message'] ?? widget.replyingTo?['message_body'] ?? widget.replyingTo?['text'] ?? 'Media';
    return Container(
      margin: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 0),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(16.r), border: Border(left: BorderSide(color: const Color(0xFF00A884), width: 4.w))),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text("Replying to", style: TextStyle(color: const Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 11.sp)), Text(message.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 14.sp))])),
          IconButton(onPressed: widget.onCancelReply, icon: Icon(Icons.close, size: 20.sp, color: Colors.grey)),
        ],
      ),
    );
  }
}
