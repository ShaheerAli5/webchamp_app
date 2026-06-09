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
  static String updateContact(String phoneNumber) =>
      '/vendor/contact/update/$phoneNumber';
  static const String assignTeamMember = '/vendor/contact/assign-team-member';
  static String contactChatBoxData(String contactUid) =>
      '/vendor/whatsapp/contact/chat-box-data/$contactUid';
  static List<String> contactMessages(String contactUid) => [
        '/vendor/whatsapp/contact/chat/messages/$contactUid',
        '/vendor/whatsapp/contact/chat/$contactUid/messages',
        '/vendor/whatsapp/contact/chat-messages/$contactUid',
        '/vendor/whatsapp/contact/messages/$contactUid',
        '/vendor/whatsapp/contact/chat/messages-data/$contactUid',
        '/vendor/whatsapp/contact/chat/message-data/$contactUid',
        '/vendor/whatsapp/contact/chat-history/$contactUid',
      ];
  static const String createLabel = '/vendor/whatsapp/contact/create-label';
  static const String updateLabel = '/vendor/whatsapp/contact/chat/edit-label';
  static String deleteLabel(String labelUid) =>
      '/vendor/whatsapp/contact/chat/delete-label/$labelUid';
  static const String assignLabels = '/vendor/whatsapp/contact/chat/assign-labels';
  static const String sendMessage = '/vendor/whatsapp/contact/chat/send-message';
}
