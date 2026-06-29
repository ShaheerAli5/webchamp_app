import 'dart:convert';

class SavedAccountModel {
  final String userId;
  final String name;
  final String email;
  final String? profileImage;
  final String accessToken;
  final String? refreshToken;
  final DateTime loginTimestamp;
  final DateTime lastUsedAt;
  final bool isCurrentAccount;
  final bool needsReauth;
  final Map<String, dynamic> userData;

  SavedAccountModel({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImage,
    required this.accessToken,
    this.refreshToken,
    required this.loginTimestamp,
    required this.lastUsedAt,
    this.isCurrentAccount = false,
    this.needsReauth = false,
    required this.userData,
  });

  SavedAccountModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? profileImage,
    String? accessToken,
    String? refreshToken,
    DateTime? loginTimestamp,
    DateTime? lastUsedAt,
    bool? isCurrentAccount,
    bool? needsReauth,
    Map<String, dynamic>? userData,
  }) {
    return SavedAccountModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      loginTimestamp: loginTimestamp ?? this.loginTimestamp,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isCurrentAccount: isCurrentAccount ?? this.isCurrentAccount,
      needsReauth: needsReauth ?? this.needsReauth,
      userData: userData ?? this.userData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'loginTimestamp': loginTimestamp.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'isCurrentAccount': isCurrentAccount,
      'needsReauth': needsReauth,
      'userData': userData,
    };
  }

  factory SavedAccountModel.fromMap(Map<String, dynamic> map) {
    return SavedAccountModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'],
      accessToken: map['accessToken'] ?? '',
      refreshToken: map['refreshToken'],
      loginTimestamp: DateTime.parse(map['loginTimestamp'] ?? DateTime.now().toIso8601String()),
      lastUsedAt: DateTime.parse(map['lastUsedAt'] ?? map['loginTimestamp'] ?? DateTime.now().toIso8601String()),
      isCurrentAccount: map['isCurrentAccount'] ?? false,
      needsReauth: map['needsReauth'] ?? false,
      userData: Map<String, dynamic>.from(map['userData'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedAccountModel.fromJson(String source) => SavedAccountModel.fromMap(json.decode(source));
}
