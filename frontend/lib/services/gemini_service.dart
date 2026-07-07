import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = "THÊM_API_KEY_CỦA_BẠN_Ở_ĐÂY";
  final GenerativeModel _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);

  Future<String> generateContent(String projectName, String description) async {
    final prompt = """
    Bạn là chuyên gia tạo nội dung marketing cho dự án: $projectName.
    Thông tin dự án: $description.
    Nơi triển khai: Thành phố Hồ Chí Minh.
    Hãy tạo bài đăng Fanpage hấp dẫn, thân thiện, phù hợp với người Việt.
    Tối đa 300 từ, có cấu trúc rõ ràng, kêu gọi hành động phù hợp.
    """;

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? "Không thể tạo nội dung";
  }

  Future<String> chatWithProject(String projectName, String history, String message) async {
    final prompt = """
    Dự án: $projectName.
    Lịch sử hội thoại: $history.
    Người dùng hỏi: $message.
    Trả lời chính xác, chỉ liên quan đến dự án này.
    """;
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? "Lỗi trả lời";
  }
}