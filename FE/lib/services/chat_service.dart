import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';

class ChatService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKey = '';

  Future<String> getAiResponse(String message, List<ChatMessageModel> history) async {
    if (_apiKey.isEmpty) {
      return 'Xin chào! Tôi là trợ lý của BigStyle. Tôi có thể giúp gì cho bạn về thời trang bigsize?';
    }

    try {
      final messages = [
        {
          'role': 'system',
          'content':
              'Bạn là trợ lý AI của cửa hàng thời trang BigSize tên BigStyle. '
              'Bạn chuyên tư vấn về thời trang cho người có thân hình đầy đặn. '
              'Hãy trả lời bằng tiếng Việt, thân thiện, chuyên nghiệp. '
              'Gợi ý sản phẩm phù hợp với từng dáng người. '
              'Tagline: "Mặc đẹp không giới hạn"',
        },
        ...history.map((m) => {
              'role': m.isFromAi ? 'assistant' : 'user',
              'content': m.content,
            }),
        {'role': 'user', 'content': message},
      ];

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      }
      return 'Xin lỗi, tôi đang gặp sự cố. Vui lòng thử lại sau.';
    } catch (_) {
      return 'Xin lỗi, tôi đang gặp sự cố kết nối. Vui lòng thử lại sau.';
    }
  }
}
