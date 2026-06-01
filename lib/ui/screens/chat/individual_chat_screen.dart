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
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  bool _showEmoji = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
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

  void _handleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
      if (_showEmoji) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showEmoji) setState(() => _showEmoji = false);
              },
              child: Container(
                width: 390.w,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    bool isMe = index % 2 != 0;
                    return _buildMessageBubble(
                      isMe: isMe,
                      message: isMe ? 'Waiting for you' : 'I will let you know',
                      time: '12:59AM',
                    );
                  },
                ),
              ),
            ),
          ),
          if (_showEmoji) _buildEmojiPlaceholder(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmojiPlaceholder() {
    return Container(
      height: 250.h,
      color: Colors.white,
      child: const Center(
        child: Text("Emoji Picker Placeholder", style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4.h,
        bottom: 8.h,
        left: 4.w,
        right: 8.w,
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
            onPressed: () => context.pop(),
          ),
          SizedBox(width: 4.w),
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFFF0F2F5),
            child: Icon(Icons.person, color: Colors.black54, size: 24.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              widget.name,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: Colors.black, size: 24.sp),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.call, color: Colors.black, size: 22.sp),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black, size: 24.sp),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required bool isMe, required String message, required String time}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 203.w,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: isMe 
            ? EdgeInsets.fromLTRB(9.w, 5.h, 9.w, 5.h)
            : EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 5.h),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        constraints: BoxConstraints(
          minHeight: 44.h,
          maxWidth: 203.w,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 14.sp, color: Colors.black, height: 1.2),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.done_all, size: 14.sp, color: Colors.blue),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      width: 390.w,
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 8.h), // Adjusted padding
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _handleEmoji,
                    icon: Icon(
                      _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: const Color(0xFF8696A0),
                      size: 26.sp,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      onTap: () {
                        if (_showEmoji) setState(() => _showEmoji = false);
                      },
                      style: TextStyle(fontSize: 17.sp, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(
                          color: const Color(0xFF8696A0),
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _handleAttachment,
                    icon: Icon(Icons.attach_file, color: const Color(0xFF8696A0), size: 24.sp),
                  ),
                  if (!_isTyping)
                    IconButton(
                      onPressed: _handleCamera,
                      icon: Icon(Icons.camera_alt, color: const Color(0xFF8696A0), size: 24.sp),
                    ),
                  if (_isTyping) SizedBox(width: 8.w),
                ],
              ),
            ),
          ),
          SizedBox(width: 5.w),
          GestureDetector(
            onLongPress: () {
              if (!_isTyping) {
                Fluttertoast.showToast(msg: "Recording voice message...");
              }
            },
            onTap: () {
              if (_isTyping) {
                Fluttertoast.showToast(msg: "Message sent!");
                _messageController.clear();
              }
            },
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: const BoxDecoration(
                color: Color(0xFF00A884), // WhatsApp Green
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _isTyping ? Icons.send : Icons.mic,
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
