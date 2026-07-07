class ProjectModel {
  String? id;
  final String name;
  final String description;
  final String pageId;
  final String pageName;
  final String pageToken;
  final String userId;
  final DateTime createdAt;

  ProjectModel({
    this.id,
    required this.name,
    required this.description,
    required this.pageId,
    required this.pageName,
    required this.pageToken,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pageId': pageId,
      'pageName': pageName,
      'pageToken': pageToken,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProjectModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      pageId: map['pageId'] ?? '',
      pageName: map['pageName'] ?? '',
      pageToken: map['pageToken'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}