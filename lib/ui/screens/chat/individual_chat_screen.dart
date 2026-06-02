import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class IndividualChatScreen extends StatefulWidget {
  final String name;
  const IndividualChatScreen({super.key, required this.name});

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

  void _handleSend() {
    if (_messageController.text.trim().isNotEmpty) {
      // Logic for sending message
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: ChatAppBar(name: widget.name),
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
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    reverse: true,
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      // Simulated message grouping logic
                      bool isMe = index % 3 == 0;
                      bool isFirstInGroup = index == 19 || (index < 19 && (index + 1) % 3 != 0);

                      return ChatBubble(
                        message: isMe 
                            ? (index == 0 ? "Wait for me, I am coming in 5 minutes!" : "Check out this design!")
                            : "Sure, I will be waiting. Let me know when you reach.",
                        time: "12:59 PM",
                        isMe: isMe,
                        isFirstInGroup: isFirstInGroup,
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
}

class ChatAppBar extends StatelessWidget {
  final String name;
  const ChatAppBar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
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
                  'online',
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
          onPressed: () {},
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
