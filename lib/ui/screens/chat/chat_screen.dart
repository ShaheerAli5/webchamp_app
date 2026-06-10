import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isSetupCompleted = true;
  Timer? _pollingTimer;
  bool _isPolling = false;
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchContacts();
      _startPolling();
    });
  }

  Future<void> _fetchContacts() async {
    await context.read<ContactProvider>().getContacts(perPage: 100);
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (mounted && !_isPolling) {
        _isPolling = true;
        await _fetchContacts();
        _isPolling = false;
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _isSetupCompleted ? _buildFAB() : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isSetupCompleted) ...[
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildFinishSetupBanner(),
              ),
            ] else ...[
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(
                child: Consumer<ContactProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.contacts.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final contactsWithChats = [...provider.contacts]
                      ..sort(_sortContactsByLatestMessage);

                    final filtered = _activeFilter == 'unread'
                        ? contactsWithChats
                            .where((c) => (c['unread_messages_count'] ?? 0) > 0)
                            .toList()
                        : contactsWithChats;
                    
                    if (filtered.isEmpty) {
                      return const Center(child: Text("No chats yet"));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final contact = filtered[index];
                        final name = _contactName(contact);
                        final uid = _contactUid(contact);
                        final lastMsg = _contactLatestMessage(contact);
                        final time = _contactLatestMessageTime(contact);
                        final unreadCount = contact['unread_messages_count'];

                        return _buildChatItem(
                          uid: uid,
                          name: _sanitizeText(name),
                          subtext: _sanitizeText(lastMsg),
                          time: time,
                          isUnread: (unreadCount ?? 0) > 0,
                          unreadCount: unreadCount?.toString(),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'WhatsApp',
            style: TextStyle(
              color: const Color(0xFF151515),
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              letterSpacing: 0.06,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined, size: 24.sp, color: Colors.black),
              SizedBox(width: 22.w),
              Icon(Icons.more_vert, size: 24.sp, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  int _sortContactsByLatestMessage(dynamic left, dynamic right) {
    final leftTime = _contactLatestDateTime(left);
    final rightTime = _contactLatestDateTime(right);

    if (leftTime == null && rightTime == null) return 0;
    if (leftTime == null) return 1;
    if (rightTime == null) return -1;

    return rightTime.compareTo(leftTime);
  }

  String _contactName(dynamic contact) {
    if (contact is! Map) return 'No Name';

    final firstName = contact['first_name'] ?? contact['fname'] ?? '';
    final lastName = contact['last_name'] ?? contact['lname'] ?? '';
    final fullName = contact['full_name'] ?? contact['name'] ?? '';
    final name = fullName.toString().isNotEmpty
        ? fullName.toString()
        : '$firstName $lastName'.trim();

    return name.isNotEmpty ? name : 'No Name';
  }

  String _contactUid(dynamic contact) {
    if (contact is! Map) return '';

    return contact['_uid']?.toString() ??
        contact['uid']?.toString() ??
        contact['id']?.toString() ??
        '';
  }

  String _contactLatestMessage(dynamic contact) {
    if (contact is! Map) return '';

    final lastMessage = contact['last_message'];
    if (lastMessage is Map) {
      // 1. Check for explicit text content
      final text = lastMessage['message'] ??
          lastMessage['text'] ??
          lastMessage['body'] ??
          lastMessage['message_body'] ??
          lastMessage['caption'];

      if (text != null && text.toString().trim().isNotEmpty) {
        return text.toString();
      }

      // 2. Check for type based identification
      final type = (lastMessage['message_type'] ?? lastMessage['type'] ?? '').toString().toLowerCase();
      if (type == 'audio' || type == 'voice' || type == 'ptt') return 'voice';
      if (type == 'image') return '📷 Image';
      if (type == 'video') return '🎥 Video';
      if (type == 'document') return '📄 Document';

      // 3. Check webhook deep extraction
      final data = lastMessage['__data'];
      if (data is Map) {
        try {
          final msg = data['webhook_responses']?['incoming']?[0]?['changes']?[0]?['value']?['messages']?[0];
          final wType = msg?['type']?.toString().toLowerCase();
          if (wType == 'audio' || wType == 'voice' || wType == 'ptt') return 'voice';
          if (wType == 'image') return '📷 Image';
          if (wType == 'video') return '🎥 Video';
          if (wType == 'document') return '📄 Document';
        } catch (_) {}
      }

      // Fallback based on wamid existence
      if (lastMessage['wamid'] != null) return '📎 Media message';

      final agoTime = lastMessage['formatted_message_ago_time'];
      if (agoTime != null) return '🕐 $agoTime';
    }

    return '';
  }

  String _contactLatestMessageTime(dynamic contact) {
    final time = _contactLatestDateTime(contact);
    if (time == null) return '';

    return DateFormat('hh:mm a').format(time);
  }

  DateTime? _contactLatestDateTime(dynamic contact) {
    if (contact is! Map) return null;

    final lastMessage = contact['last_message'];
    final rawTime = contact['latest_message'] ??
        (lastMessage is Map ? lastMessage['created_at'] : null) ??
        contact['updated_at'];

    if (rawTime == null) return null;

    return DateTime.tryParse(rawTime.toString());
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(24.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ask Meta AI or Search',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.sp,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 36.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildChip('All',
              isSelected: _activeFilter == 'all',
              onTap: () => setState(() => _activeFilter = 'all')),
          _buildChip('Unread',
              isSelected: _activeFilter == 'unread',
              onTap: () => setState(() => _activeFilter = 'unread')),
          _buildChip('Groups'),
          _buildChip('New List',
              isAction: true,
              hasAddIcon: true,
              onTap: () => context.push(AppRoutes.createNewList)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {bool isSelected = false, bool isAction = false, bool hasAddIcon = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD8FDD2) : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: isSelected ? const Color(0xFF25D366) : const Color(0xFFD1D1D1), width: 1.w),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAddIcon) ...[
              Icon(Icons.add, size: 16.sp, color: const Color(0xFF667085)),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF075E54) : const Color(0xFF667085),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required String uid,
    required String name,
    required String subtext,
    required String time,
    IconData? icon,
    Color? iconColor,
    Color? subtextColor,
    bool isUnread = false,
    String? unreadCount,
    bool isGroup = false,
  }) {
    return ListTile(
      onTap: () => context.push('/chat-detail/$uid/$name'),
      leading: CircleAvatar(
        radius: 26.r,
        backgroundColor: const Color(0xFFF0F2F5),
        child: _sanitizeText(name).isNotEmpty
            ? Text(
                _sanitizeText(name)[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              )
            : Icon(isGroup ? Icons.group : Icons.person,
                color: Colors.black54, size: 28.sp),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: isUnread ? const Color(0xFF25D366) : Colors.grey,
            ),
          ),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16.sp, color: iconColor),
                  SizedBox(width: 4.w),
                ],
                Expanded(
                  child: Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: subtextColor ?? Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread && unreadCount != null)
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount,
                style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        color: const Color(0xFF21C063),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.add_comment_rounded, color: Colors.white, size: 28.sp),
      ),
    );
  }

  Widget _buildFinishSetupBanner() {
    return Container(
      height: 95.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEECD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8953D).withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: const Color(0xFFD8953D).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(Iconsax.info_circle, color: const Color(0xFF633600), size: 14.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Finish setup',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: const Color(0xFF633600),
                        fontFamily: 'Geist',
                        height: 17/13,
                        letterSpacing: -0.08,
                      ),
                    ),
                    Icon(Icons.close, size: 14.sp, color: const Color(0xFF633600)),
                  ],
                ),
                Text(
                  'Connect WhatsApp Cloud API',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF633600),
                    fontFamily: 'Geist',
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _isSetupCompleted = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDFDEDA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Complete setup',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF161B20),
                            fontFamily: 'Geist',
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_outward, size: 11.sp, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
