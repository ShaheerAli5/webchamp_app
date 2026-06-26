class StatusModel {
  final String id;
  final String userId;
  final String mediaType; // 'image' or 'video'
  final String mediaUrl;
  final String? thumbnail;
  final String? caption;
  final DateTime createdAt;

  StatusModel({
    required this.id,
    required this.userId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnail,
    this.caption,
    required this.createdAt,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      mediaType: json['media_type'],
      mediaUrl: json['media_url'],
      thumbnail: json['thumbnail'],
      caption: json['caption'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'thumbnail': thumbnail,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
