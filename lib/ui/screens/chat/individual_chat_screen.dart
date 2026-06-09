import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      Fluttertoast.showToast(msg: "Photo captured: ${photo.name}");
    }
  }

  Future<void> _handleAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      Fluttertoast.showToast(msg: "File selected: ${result.files.single.name}");
    }
  }

  void _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _messageController.clear();
      final success = await context.read<ContactProvider>().sendMessage(
        contactUid: widget.uid,
        message: text,
      );
      
      if (!success) {
        Fluttertoast.showToast(msg: "Failed to send message");
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
                  radius: 40.r,
                  backgroundColor: const Color(0xFFF0F2F5),
                  child: Icon(Icons.person, color: Colors.grey, size: 50.sp),
                ),
                SizedBox(height: 12.h),
                Text(
                  widget.name,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    children: [
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
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: ChatAppBar(name: widget.name, onInfoTap: _showContactInfo),
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
                  child: Consumer<ContactProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading && provider.messages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final messages = provider.messages;
                      
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
                          final text = _messageText(messageData);
                          final time = _messageTime(messageData);

                          return ChatBubble(
                            message: text,
                            time: time,
                            isMe: isMe,
                            isFirstInGroup: true, // Simplified for now
                          );
                        },
                      );
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadChatData() async {
    final provider = context.read<ContactProvider>();
    if (provider.contacts.isEmpty) {
      await provider.getContacts(perPage: 100);
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

  String _messageText(dynamic messageData) {
    if (messageData is! Map) return '';

    final text = messageData['message'] ??
        messageData['text'] ??
        messageData['body'] ??
        messageData['message_body'] ??
        messageData['description'] ??
        messageData['caption'];

    if (text != null && text.toString().trim().isNotEmpty) {
      return text.toString();
    }

    final messageType =
        (messageData['message_type'] ?? messageData['type'] ?? '').toString();
    if (messageType.isNotEmpty && messageType != 'text') {
      return messageType[0].toUpperCase() + messageType.substring(1);
    }

    return '';
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
  final VoidCallback onInfoTap;
  const ChatAppBar({super.key, required this.name, required this.onInfoTap});

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
              child: Icon(Icons.person, color: Colors.grey, size: 28.sp),
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
          onPressed: () {},
          icon: const Icon(Icons.videocam, color: Color(0xFF008069)),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.call, color: Color(0xFF008069)),
        ),
        IconButton(
          onPressed: onInfoTap,
          icon: const Icon(Icons.more_vert, color: Color(0xFF667781)),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final bool isFirstInGroup;

  const ChatBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMe,
    this.isFirstInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4.h,
          top: isFirstInGroup ? 8.h : 0,
        ),
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isMe ? 16.r : (isFirstInGroup ? 4.r : 16.r)),
            bottomRight: Radius.circular(isMe ? (isFirstInGroup ? 4.r : 16.r) : 16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Text(
                message,
                style: TextStyle(
                  color: const Color(0xFF111B21),
                  fontSize: 15.sp,
                  height: 1.3,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: const Color(0xFF667781),
                    fontSize: 11.sp,
                    fontFamily: 'Inter',
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.done_all, color: const Color(0xFF34B7F1), size: 16.sp),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTyping;
  final VoidCallback onAttachment;
  final VoidCallback onCamera;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isTyping,
    required this.onAttachment,
    required this.onCamera,
    required this.onSend,
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
                    color: Colors.black.withOpacity(0.05),
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
                          hintText: 'Message',
                          hintStyle: TextStyle(
                            color: const Color(0xFF8696A0),
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
                  if (!isTyping)
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
            child: Container(
              height: 48.w,
              width: 48.w,
              decoration: const BoxDecoration(
                color: Color(0xFF00A884),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isTyping ? Icons.send : Icons.mic,
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
