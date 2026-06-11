import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../features/contacts/presentation/providers/contact_provider.dart';

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
  
  // Real-time polling
  Timer? _pollingTimer;
  bool _isPolling = false;
  
  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
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
    if (text == null || text.trim().isEmpty) return '';
    try {
      // Remove characters that cause malformed UTF-16
      return text.runes
          .where((r) => r <= 0xFFFF || (r >= 0x10000 && r <= 0x10FFFF))
          .map((r) => String.fromCharCode(r))
          .join()
          .trim();
    } catch (_) {
      return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
    }
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
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _sendImage(photo.path);
    }
  }

  Future<void> _handleAttachment() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 250.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Text("Select attachment",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(Icons.image, "Gallery", Colors.purple, () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) Navigator.pop(context, 'image:${image.path}');
                }),
                _buildAttachmentOption(Icons.videocam, "Video", Colors.orange, () async {
                  final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                  if (video != null) Navigator.pop(context, 'video:${video.path}');
                }),
                _buildAttachmentOption(Icons.insert_drive_file, "Document", Colors.blue, () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles();
                  if (result != null) Navigator.pop(context, 'file:${result.files.single.path}');
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
          CircleAvatar(
            radius: 30.r,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }

  void _sendImage(String path) async {
    final provider = context.read<ContactProvider>();
    Fluttertoast.showToast(msg: "Sending image...");
    final success = await provider.sendImageMessage(
      contactUid: widget.uid,
      filePath: path,
    );

    if (!success) {
      Fluttertoast.showToast(
          msg: provider.errorMessage ?? "Failed to send image");
    } else {
      _loadChatData();
    }
  }

  void _sendVideo(String path) async {
    final provider = context.read<ContactProvider>();
    Fluttertoast.showToast(msg: "Sending video...");
    final success = await provider.sendVideoMessage(
      contactUid: widget.uid,
      filePath: path,
    );

    if (!success) {
      Fluttertoast.showToast(
          msg: provider.errorMessage ?? "Failed to send video");
    } else {
      _loadChatData();
    }
  }

  void _sendDocument(String path) async {
    final provider = context.read<ContactProvider>();
    Fluttertoast.showToast(msg: "Sending document...");
    // We can reuse sendMedia or add a specific one. Let's add sendDocumentMessage to provider.
    final success = await provider.sendDocumentMessage(
      contactUid: widget.uid,
      filePath: path,
    );

    if (!success) {
      Fluttertoast.showToast(
          msg: provider.errorMessage ?? "Failed to send document");
    } else {
      _loadChatData();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );
        await _audioRecorder.start(config, path: path);
        
        setState(() {
          _isRecording = true;
          _recordingPath = path;
        });
        debugPrint('🎙️ Recording started: $path');
      }
    } catch (e) {
      debugPrint('❌ Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      
      if (path != null) {
        Fluttertoast.showToast(msg: "Recording saved. Sending...");
        _sendVoiceMessage(path);
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  void _sendVoiceMessage(String path) async {
    final provider = context.read<ContactProvider>();
    final success = await provider.sendVoiceMessage(
      contactUid: widget.uid,
      filePath: path,
    );

    if (!success) {
      Fluttertoast.showToast(
          msg: provider.errorMessage ?? "Failed to send voice message");
    } else {
      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final provider = context.read<ContactProvider>();
      _messageController.clear();
      final success = await provider.sendMessage(
        contactUid: widget.uid,
        message: text,
      );

      if (!success) {
        Fluttertoast.showToast(
            msg: provider.errorMessage ??
                "Failed to send message. Please try again.");
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _showContactInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ContactProvider>(
        builder: (context, provider, child) {
          final contact = provider.contacts.firstWhere(
            (c) => (c['_uid'] ?? c['uid']) == widget.uid,
            orElse: () => <String, dynamic>{},
          );

          final name = contact['full_name'] ?? contact['first_name'] ?? widget.name;
          final imageUrl = contact['profile_image'] ?? contact['image_url'];
          final phone = contact['wa_id'] ?? contact['phone_number'] ?? '';
          final email = contact['email'] ?? '';

          return Container(
            height: 0.85.sh,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 20.h),
                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: const Color(0xFFF0F2F5),
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? Text(
                          _sanitizeText(name).isNotEmpty
                              ? _sanitizeText(name)[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        )
                      : null,
                ),
                SizedBox(height: 12.h),
                Text(
                  _sanitizeText(name),
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close info sheet
                    context.push('/edit-contact', extra: contact).then((_) {
                      provider.getContacts(); // Refresh list
                    });
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit Contact"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007176),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                  ),
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    children: [
                      if (email.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text("Email"),
                          subtitle: Text(email),
                        ),
                      _buildInfoSection(
                        "Labels", 
                        provider.labels, 
                        Icons.label_outline,
                        onAdd: () => _showAddLabelDialog(provider),
                      ),
                      SizedBox(height: 24.h),
                      _buildInfoSection(
                        "Assigned Team Members", 
                        provider.teamMembers, 
                        Icons.people_outline,
                        onAdd: () => _showAssignTeamMemberDialog(provider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddLabelDialog(ContactProvider provider) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Label"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: "Label Title"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.createLabel(
                title: titleController.text,
                textColor: "#FFFFFF",
                bgColor: "#007176",
              );
              if (success) {
                Navigator.pop(context);
                provider.getContactChatBoxData(widget.uid);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showAssignTeamMemberDialog(ContactProvider provider) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Assign Team Member"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: "Username or Email"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // Note: We need phone number here according to API
              // We'll try to find it in the current contact list
              final contact = provider.contacts.firstWhere((c) => (c['_uid'] ?? c['uid']) == widget.uid, orElse: () => null);
              final phone = contact?['wa_id'] ?? contact?['phone_number'];
              
              if (phone != null) {
                final success = await provider.assignTeamMember(
                  phoneNumber: phone,
                  usernameOrEmail: emailController.text,
                );
                if (success) {
                  Navigator.pop(context);
                  provider.getContactChatBoxData(widget.uid);
                }
              } else {
                Fluttertoast.showToast(msg: "Contact phone not found");
              }
            },
            child: const Text("Assign"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<dynamic> items, IconData icon, {VoidCallback? onAdd}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20.sp, color: const Color(0xFF008069)),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF008069)),
                ),
              ],
            ),
            if (onAdd != null)
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF008069)),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        if (items.isEmpty)
          const Text("None assigned", style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: items.map((item) {
              final label = item is Map ? (item['title'] ?? item['name'] ?? item['username'] ?? '') : item.toString();
              return Chip(
                label: Text(label),
                backgroundColor: const Color(0xFFE7F3F3),
                labelStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF006B70)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  // TODO: Implement unassign logic if needed
                },
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, child) {
        final contact = provider.contacts.firstWhere(
          (c) => (c['_uid'] ?? c['uid']) == widget.uid,
          orElse: () => <String, dynamic>{},
        );

        final name = contact['full_name'] ?? contact['first_name'] ?? widget.name;
        final imageUrl = contact['profile_image'] ?? contact['image_url'];

        return Scaffold(
          backgroundColor: const Color(0xFFE5DDD5),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60.h),
            child: ChatAppBar(
              name: _sanitizeText(name),
              uid: widget.uid,
              imageUrl: imageUrl,
              onInfoTap: _showContactInfo,
            ),
          ),
          body: Stack(
            children: [
              // Background Doodle
              Opacity(
                opacity: 0.08,
                child: Image.network(
                  'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              SafeArea(
                bottom: true,
                child: Column(
                  children: [
                    Expanded(
                      child: provider.isLoading && provider.messages.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : _buildMessagesList(provider.messages, imageUrl),
                    ),
                    ChatInputBar(
                      controller: _messageController,
                      focusNode: _focusNode,
                      isTyping: _isTyping,
                      isRecording: _isRecording,
                      onAttachment: _handleAttachment,
                      onCamera: _handleCamera,
                      onSend: _handleSend,
                      onLongPressStart: _startRecording,
                      onLongPressEnd: _stopRecording,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(List<dynamic> messages, String? contactImageUrl) {
    if (messages.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12.r),
          ),
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

        return ChatBubble(
          content: content,
          time: time,
          isMe: isMe,
          type: type,
          messageData: messageData,
          imageUrl: contactImageUrl,
        );
      },
    );
  }

  Future<void> _loadChatData() async {
    final provider = context.read<ContactProvider>();
    if (provider.contacts.isEmpty) {
      await provider.getContacts();
    }
    await provider.getContactChatBoxData(widget.uid);
  }

  bool _isOutgoingMessage(dynamic messageData) {
    if (messageData is! Map) return false;

    final incoming = messageData['is_incoming_message'];
    if (incoming == 0 || incoming == false || incoming == '0') return true;
    if (incoming == 1 || incoming == true || incoming == '1') return false;

    final type = messageData['type']?.toString().toLowerCase();
    final status = messageData['status']?.toString().toLowerCase();
    final direction = messageData['direction']?.toString().toLowerCase();

    return type == 'outgoing' ||
        direction == 'outgoing' ||
        status == 'sent' ||
        status == 'delivered' ||
        status == 'read';
  }

  String _getMessageType(dynamic messageData) {
    if (messageData is! Map) return 'text';

    // Guideline: Priority extraction from __data['media_values']['type']
    final mediaValues = messageData['__data']?['media_values'];
    if (mediaValues is Map) {
      final type = mediaValues['type']?.toString().toLowerCase();
      if (type == 'audio' || type == 'voice' || type == 'ptt') return 'voice';
      if (type != null && type.isNotEmpty) return type;
    }

    // Legacy/Fallback check
    final type = (messageData['message_type'] ?? messageData['type'] ?? '').toString().toLowerCase();
    if (type == 'audio' || type == 'voice' || type == 'ptt') return 'voice';
    if (type == 'image') return 'image';
    if (type == 'video') return 'video';
    if (type == 'document' || type == 'file') return 'document';

    return 'text';
  }

  dynamic _getMessageContent(dynamic messageData) {
    if (messageData is! Map) return '';

    // 1. Guideline: Priority extraction from __data['media_values']['link']
    final mediaValues = messageData['__data']?['media_values'];
    if (mediaValues is Map && mediaValues['link'] != null) {
      final link = mediaValues['link'].toString();
      if (link.isNotEmpty) return link;
    }

    // 2. Fallback: Check direct media keys (common in different API versions)
    final mediaLink = messageData['media_url'] ??
        messageData['link'] ??
        messageData['attachment_url'] ??
        messageData['attachment'] ??
        messageData['uploaded_media_file_name'] ??
        messageData['audio_url'];

    if (mediaLink != null && mediaLink.toString().isNotEmpty) {
      String path = mediaLink.toString();
      if (path.startsWith('http')) return path;
      
      // Clean path and construct absolute URL if it's a relative path/filename
      if (path.startsWith('/')) path = path.substring(1);
      if (path.startsWith('storage/')) path = path.substring(8);
      
      // If no folder is present, guess based on type
      if (!path.contains('/')) {
        final type = _getMessageType(messageData);
        if (type == 'voice' || type == 'audio') path = 'whatsapp_audio/$path';
        else if (type == 'image') path = 'whatsapp_image/$path';
        else if (type == 'video') path = 'whatsapp_video/$path';
        else if (type == 'document') path = 'whatsapp_document/$path';
      }
      
      return 'https://wabchamp.com/storage/$path';
    }

    // 3. Final fallback: Text content
    final text = messageData['message'] ??
        messageData['message_body'] ??
        messageData['body'] ??
        messageData['text'] ??
        '';

    return text.toString();
  }

  String _messageTime(dynamic messageData) {
    if (messageData is! Map) return '';

    final rawTime = messageData['created_at'] ??
        messageData['updated_at'] ??
        messageData['messaged_at'] ??
        messageData['timestamp'];

    if (rawTime == null) return '';

    final parsedTime = DateTime.tryParse(rawTime.toString());
    if (parsedTime == null) return '';

    return DateFormat('hh:mm a').format(parsedTime);
  }
}

class ChatAppBar extends StatelessWidget {
  final String name;
  final String uid; // Added uid
  final String? imageUrl;
  final VoidCallback onInfoTap;
  const ChatAppBar({
    super.key,
    required this.name,
    required this.uid,
    this.imageUrl,
    required this.onInfoTap,
  });

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
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF008069)),
            ),
            CircleAvatar(
              radius: 20.r,
              backgroundColor: const Color(0xFFF0F2F5),
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null
                  ? Icon(Icons.person, color: Colors.grey, size: 28.sp)
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: const Color(0xFF111B21),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'tap for info',
                    style: TextStyle(
                      color: const Color(0xFF667781),
                      fontSize: 12.sp,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _startCall(context, true),
          icon: const Icon(Icons.videocam, color: Color(0xFF008069)),
        ),
        IconButton(
          onPressed: () => _startCall(context, false),
          icon: const Icon(Icons.call, color: Color(0xFF008069)),
        ),
        IconButton(
          onPressed: onInfoTap,
          icon: const Icon(Icons.more_vert, color: Color(0xFF667781)),
        ),
      ],
    );
  }

  void _startCall(BuildContext context, bool isVideo) {
    // Generate a channel name based on UID and current time or some unique id
    final channelName = "channel_$uid";
    context.push('/call/$channelName/$isVideo');
  }
}

class ChatBubble extends StatelessWidget {
  final dynamic content;
  final String time;
  final bool isMe;
  final String type;
  final dynamic messageData;
  final String? imageUrl;

  const ChatBubble({
    super.key,
    required this.content,
    required this.time,
    required this.isMe,
    required this.type,
    this.messageData,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 2.h,
          top: 2.h,
          left: isMe ? 64.w : 12.w,
          right: isMe ? 12.w : 64.w,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: type == 'image' || type == 'video'
            ? EdgeInsets.all(4.w)
            : EdgeInsets.fromLTRB(10.w, 5.h, 10.w, 5.h),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
            bottomRight: Radius.circular(isMe ? 4.r : 16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildContent(context),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: const Color(0xFF667781),
                        fontSize: 10.sp,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done_all,
                          color: const Color(0xFF34B7F1), size: 14.sp),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (type) {
      case 'voice':
      case 'audio':
        return VoiceMessageBubble(
          audioUrl: content.toString(),
          isMe: isMe,
          messageData: messageData,
          imageUrl: imageUrl,
        );
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            content.toString(),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150.h,
                width: 200.w,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150.h,
              width: 200.w,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, color: Colors.grey),
                  SizedBox(height: 4.h),
                  Text("Failed to load image", style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      case 'video':
        return Container(
          width: 200.w,
          height: 150.h,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          ),
        );
      case 'document':
      case 'file':
        return Container(
          width: 200.w,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFC3E7B2) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.grey),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  content.toString().split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              const Icon(Icons.download, color: Colors.grey, size: 20),
            ],
          ),
        );
      default:
        return Text(
          content.toString(),
          style: TextStyle(
            color: const Color(0xFF111B21),
            fontSize: 15.sp,
            height: 1.3,
          ),
        );
    }
  }
}

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final dynamic messageData;
  final String? imageUrl;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.messageData,
    this.imageUrl,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _player.onDurationChanged.listen((duration) {
      if (mounted && duration > Duration.zero) {
        setState(() {
          _duration = duration;
          _isLoading = false;
        });
      }
    });
    _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.completed;
          _position = Duration.zero;
        });
      }
    });

    if (widget.audioUrl.isNotEmpty && widget.audioUrl.startsWith('http')) {
      try {
        await _player.setSource(UrlSource(widget.audioUrl));
        
        // Try to get duration immediately if already available in metadata
        final d = await _player.getDuration();
        if (mounted) {
          setState(() {
            if (d != null && d > Duration.zero) _duration = d;
            _isLoading = false; // Source is set, we can allow playback attempts
          });
        }
      } catch (e) {
        debugPrint('Error setting source: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayback() async {
    if (widget.audioUrl.isEmpty || !widget.audioUrl.startsWith('http')) {
      debugPrint('❌ Invalid Audio URL: ${widget.audioUrl}');
      Fluttertoast.showToast(msg: "Voice message unavailable");
      return;
    }
    
    debugPrint('🎵 Attempting to play: ${widget.audioUrl}');
    
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      try {
        await _player.play(UrlSource(widget.audioUrl));
        await _player.setPlaybackRate(_playbackSpeed);
      } catch (e) {
        debugPrint('❌ Error playing audio: $e');
        Fluttertoast.showToast(msg: "Playback error");
      }
    }
  }

  void _changeSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    _player.setPlaybackRate(_playbackSpeed);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isMe) ...[
            Stack(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: widget.imageUrl != null ? NetworkImage(widget.imageUrl!) : null,
                  child: widget.imageUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.mic, color: Colors.blue, size: 14.sp),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: _togglePlayback,
            child: _isLoading 
              ? SizedBox(
                  width: 30.sp,
                  height: 30.sp,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFF667781),
                  size: 30.sp,
                ),
          ),
          SizedBox(
            width: 130.w, // Fixed width for the waveform area within adaptive bubble
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform placeholder
                SizedBox(
                  height: 30.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(35, (index) {
                      final progress = _duration.inMilliseconds > 0 
                          ? _position.inMilliseconds / _duration.inMilliseconds 
                          : 0.0;
                      final isPlayed = (index / 35.0) < progress;
                      
                      return Container(
                        width: 2.w,
                        height: 6.h + (index % 8) * 3.h,
                        decoration: BoxDecoration(
                          color: isPlayed ? Colors.blue : const Color(0xFFB0B9BD),
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      );
                    }),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(fontSize: 10.sp, color: const Color(0xFF667781)),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(fontSize: 10.sp, color: const Color(0xFF667781)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _changeSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${_playbackSpeed.toString().replaceAll('.0', '')}x",
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTyping;
  final bool isRecording;
  final VoidCallback onAttachment;
  final VoidCallback onCamera;
  final VoidCallback onSend;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isTyping,
    required this.isRecording,
    required this.onAttachment,
    required this.onCamera,
    required this.onSend,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF8696A0)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: 5,
                        minLines: 1,
                        cursorColor: const Color(0xFF00A884),
                        style: TextStyle(fontSize: 17.sp, color: const Color(0xFF111B21)),
                        decoration: InputDecoration(
                          hintText: isRecording ? 'Recording...' : 'Message',
                          hintStyle: TextStyle(
                            color: isRecording ? Colors.red : const Color(0xFF8696A0),
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onAttachment,
                    icon: Transform.rotate(
                      angle: -0.7,
                      child: const Icon(Icons.attach_file, color: Color(0xFF8696A0)),
                    ),
                  ),
                  if (!isTyping && !isRecording)
                    IconButton(
                      onPressed: onCamera,
                      icon: const Icon(Icons.camera_alt, color: Color(0xFF8696A0)),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 5.w),
          GestureDetector(
            onTap: isTyping ? onSend : null,
            onLongPress: !isTyping ? onLongPressStart : null,
            onLongPressUp: !isTyping ? onLongPressEnd : null,
            child: Container(
              height: 48.w,
              width: 48.w,
              decoration: BoxDecoration(
                color: isRecording ? Colors.red : const Color(0xFF00A884),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isTyping ? Icons.send : (isRecording ? Icons.stop : Icons.mic),
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
