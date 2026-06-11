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

  // ✅ FIXED — was full URL, now relative path so Bearer token is included
  static const String uploadAudio =
      '/media/upload-temp-media/whatsapp_audio';
}
