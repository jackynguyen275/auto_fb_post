class FanpageModel {
  final String id;
  final String name;
  final String accessToken;

  FanpageModel({
    required this.id,
    required this.name,
    required this.accessToken,
  });

  factory FanpageModel.fromMap(Map<String, dynamic> map) {
    return FanpageModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      accessToken: map['access_token'] ?? '',
    );
  }
}