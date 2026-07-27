class LabelModel {
  final String uid;
  final String title;
  final String textColor;
  final String bgColor;

  LabelModel({
    required this.uid,
    required this.title,
    required this.textColor,
    required this.bgColor,
  });

  factory LabelModel.fromJson(Map<String, dynamic> json) {
    // 🛡️ Robust ID extraction - try all possible camelCase and snake_case keys
    final String extractedUid = (
      json['label_uid'] ?? 
      json['labelUid'] ?? 
      json['uid'] ?? 
      json['_uid'] ?? 
      json['label_id'] ?? 
      json['labelId'] ?? 
      json['id'] ?? 
      json['_id'] ?? 
      ''
    ).toString().trim();

    return LabelModel(
      uid: extractedUid,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      textColor: (json['text_color'] ?? json['textColor'] ?? '#FFFFFF').toString(),
      bgColor: (json['bg_color'] ?? json['bgColor'] ?? '#136166').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label_uid': uid,
      'title': title,
      'text_color': textColor,
      'bg_color': bgColor,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
