class UserModel {
  final int id;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? mobileNumber;
  final String email;
  final String? twoFactorSecret;

  UserModel({
    required this.id,
    this.name,
    this.firstName,
    this.lastName,
    this.username,
    this.mobileNumber,
    required this.email,
    this.twoFactorSecret,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final safeJson = Map<String, dynamic>.from(json);
    return UserModel(
      id: safeJson['id'] ?? 0,
      name: safeJson['name'],
      firstName: safeJson['first_name'],
      lastName: safeJson['last_name'],
      username: safeJson['username'],
      mobileNumber: safeJson['mobile_number'],
      email: safeJson['email'] ?? '',
      twoFactorSecret: safeJson['two_factor_secret'] ?? safeJson['google2fa_secret'],
    );
  }

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (username != null && username!.isNotEmpty) return username!;
    return 'Admin Panel';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'mobile_number': mobileNumber,
      'email': email,
      'two_factor_secret': twoFactorSecret,
    };
  }
}
