class ApiConstants {
  static const String baseUrl = 'https://wabchamp.com/api';

  static const String vendorRegister = '/register/vendor';
  static const String login = '/user/login-process';
  static const String logout = '/user/logout';
  static const String updatePassword = '/update-password';
  static const String twoFactorChallenge = '/user/two-factor-challenge';

  // Contact APIs
  static const String contactsData = '/vendor/contact/contacts-data';
  static const String contact = '/vendor/contact/contact';
  static const String createContact = '/vendor/contact/create';
  static String updateContact(String contactUid) =>
      '/vendor/contact/update/$contactUid';
  static String deleteContact(String phoneNumber) =>
      '/vendor/contact/delete/$phoneNumber';
  static const String assignTeamMember = '/vendor/contact/assign-team-member';

  // ✅ FIXED — correct chat history endpoint (chat-data returns pure JSON)
  static String chatHistory(String contactUid) =>
      '/vendor/whatsapp/contact/chat-data/$contactUid';

  // ✅ REMOVED — contactMessages list of 7 wrong guesses, all returned 404
  // Use chatHistory() above instead

  // ✅ KEPT — chat-box-data still used for labels/team members sidebar data
  static String contactChatBoxData(String contactUid) =>
      '/vendor/whatsapp/contact/chat-box-data/$contactUid';

  // Unread count — from API doc
  static const String unreadCount = '/vendor/whatsapp/chat/unread-count';
  static const String markRead = '/vendor/whatsapp/contact/chat/mark-read';

  // Clear chat history — from API doc
  static String clearChatHistory(String contactUid) =>
      '/vendor/whatsapp/contact/chat/clear-history/$contactUid';

  // Labels
  static const String createLabel = '/vendor/whatsapp/contact/create-label';
  static const String updateLabel = '/vendor/whatsapp/contact/chat/edit-label';
  static String deleteLabel(String labelUid) =>
      '/vendor/whatsapp/contact/chat/delete-label/$labelUid';
  static const String assignLabels =
      '/vendor/whatsapp/contact/chat/assign-labels';

  // Messaging
  static const String sendMessage = '/vendor/whatsapp/contact/chat/send';
  static const String sendMedia = '/vendor/whatsapp/contact/chat/send-media';
  static const String sendTemplate = '/vendor/whatsapp/contact/chat/send-template';

  // Contact Groups (Confirmed by Backend)
  static const String contactGroupsList = '/vendor/contact/groups';
  static const String createContactGroup = '/vendor/contact/group/create';
  static String updateContactGroup(String groupUid) => '/vendor/contact/group/update/$groupUid';
  static String deleteContactGroup(String groupUid) => '/vendor/contact/group/delete/$groupUid';
  static const String assignContactsToGroup = '/vendor/contacts/selected/assign-groups';
  static const String removeContactFromGroup = '/vendor/contact/remove';

  // Group APIs (WhatsApp)
  static const String groups = '/vendor/contact/groups';
  static String groupDetails(String groupUid) => '/vendor/groups/$groupUid';
  static String updateGroup(String groupUid) => '/vendor/groups/$groupUid/update';
  static String deleteGroup(String groupUid) => '/vendor/groups/$groupUid/delete';
  static String groupMembers(String groupUid) => '/vendor/groups/$groupUid/members';
  static String addGroupMembers(String groupUid) => '/vendor/groups/$groupUid/members/add';
  static String removeGroupMember(String groupUid, String memberUid) => '/vendor/groups/$groupUid/members/remove/$memberUid';
  static String updateMemberRole(String groupUid, String memberUid) => '/vendor/groups/$groupUid/members/update-role/$memberUid';
  static String groupChatHistory(String groupUid) => '/vendor/groups/$groupUid/chat-history';
  static String sendGroupMessage(String groupUid) => '/vendor/groups/$groupUid/send-message';
  static String sendGroupMedia(String groupUid) => '/vendor/groups/$groupUid/send-media';

  // ✅ FIXED — was full URL, now relative path so Bearer token is included
  static const String uploadAudio = '/media/upload-temp-media/whatsapp_audio';
  static const String uploadImage = '/media/upload-temp-media/whatsapp_image';
  static const String uploadVideo = '/media/upload-temp-media/whatsapp_video';
  static const String uploadDocument = '/media/upload-temp-media/whatsapp_document';
  
  static String uploadTempMedia(String type) => '/media/upload-temp-media/$type';
}
