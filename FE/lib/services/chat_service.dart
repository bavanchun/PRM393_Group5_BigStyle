import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

class ChatService {
  static String get _apiKey =>
      dotenv.env['CLAUDE_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-6';

  final SupabaseClient _client;

  ChatService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String _getSystemPrompt() {
    return '''Bạn là BigStyle Bot, trợ lý thời trang của BigStyle — shop thời trang bigsize hàng đầu Việt Nam.
Tagline: "Mặc đẹp không giới hạn".

NHIỆM VỤ:
- Tư vấn outfit, size, phong cách phù hợp với người bigsize
- Dựa trên thông tin sản phẩm từ database để gợi ý cụ thể
- Trả lời bằng tiếng Việt, thân thiện, tích cực về body-positive
- Khuyến khích khách hàng tự tin với vóc dáng của mình

KIẾN THỨC CHUYÊN MÔN:
- Các dáng người: quả táo (Apple), quả lê (Pear), đồng hồ cát (Hourglass), hình chữ nhật (Rectangle)
- Cách phối đồ che khuyết điểm cho từng dáng
- Chất liệu vải phù hợp cho người bigsize (cotton, modal, linen, jersey)
- Cách chọn size theo số đo cơ thể

PHONG CÁCH TRẢ LỜI:
- Thân thiện, gần gũi như người bạn
- Dùng icon phù hợp để tăng tương tác
- Ngắn gọn, dễ hiểu, có gạch đầu dòng khi cần
- Luôn kết thúc bằng câu hỏi mở để tiếp tục cuộc trò chuyện''';
  }

  Future<String> getAiResponse(
      String message, List<ChatMessageModel> history) async {
    if (_apiKey.isEmpty) {
      return _mockResponse(message);
    }

    try {
      final productContext = await _searchProducts(message);

      final messages = [
        {'role': 'user', 'content': message},
      ];

      for (final msg in history.reversed.take(20)) {
        messages.insert(0, {
          'role': msg.isFromAi ? 'assistant' : 'user',
          'content': msg.content,
        });
      }

      final systemPrompt = _getSystemPrompt();
      final contextBlock = productContext.isNotEmpty
          ? '\n\nTHÔNG TIN SẢN PHẨM HIỆN CÓ:\n$productContext'
          : '';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': '$systemPrompt$contextBlock',
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] ?? '';
      }

      return 'Xin lỗi, tôi đang gặp sự cố. Vui lòng thử lại sau.';
    } catch (_) {
      return 'Xin lỗi, tôi đang gặp sự cố kết nối. Vui lòng thử lại sau.';
    }
  }

  Future<String> _searchProducts(String query) async {
    final keywords = [
      'sản phẩm', 'áo', 'quần', 'đầm', 'váy', 'bigsize',
      'mới', 'bán chạy', 'giảm giá', 'outfit', 'đồ bộ',
    ];

    if (!keywords.any((k) => query.toLowerCase().contains(k)) || !_hasSession) {
      return '';
    }

    try {
      final data = await _client
          .from('products')
          .select('name, price, description, sizes')
          .limit(5);

      if (data.isEmpty) return '';

      return (data as List)
          .map((p) =>
              '- ${p['name']}: ${p['price']}đ (Sizes: ${(p['sizes'] as List).join(', ')})\n  Mô tả: ${p['description']?.toString().substring(0, (p['description']?.toString().length ?? 100).clamp(0, 100))}')
          .join('\n');
    } catch (_) {
      return '';
    }
  }

  bool get _hasSession => _client.auth.currentSession != null;

  Future<void> saveMessage(ChatMessageModel message) async {
    if (!_hasSession) return;
    try {
      await _client.from('chat_messages').insert(message.toMap());
    } on PostgrestException catch (e) {
      assert(false, 'ChatService.saveMessage: $e');
    } catch (_) {
      // Network/transient errors: swallow silently, chat must keep working.
    }
  }

  Future<List<ChatMessageModel>> loadHistory(String userId) async {
    if (!_hasSession) return [];
    try {
      final data = await _client
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List)
          .map((e) => ChatMessageModel.fromMap(e))
          .toList()
          .reversed
          .toList();
    } on PostgrestException catch (e) {
      assert(false, 'ChatService.loadHistory: $e');
      return [];
    } catch (_) {
      return [];
    }
  }

  String _mockResponse(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('size') || msg.contains('chọn size')) {
      return 'Chị ơi, để em tư vấn size cho chị nha! 🌸\n\n'
          'BigStyle có size từ **M đến 5XL** đầy đủ. Chị cho em biết:\n'
          '• Số đo **vòng ngực** (cm)\n'
          '• Số đo **vòng eo** (cm)\n'
          '• Số đo **vòng hông** (cm)\n\n'
          'Hoặc chị có thể vào mục "Hướng dẫn chọn size" trong từng sản phẩm để xem bảng size chi tiết nha!';
    }
    if (msg.contains('outfit') || msg.contains('body') || msg.contains('mặc')) {
      return 'Chị muốn tư vấn outfit cho dáng người nào ạ? 🌷\n\n'
          '• 🍎 **Quả táo (Apple)**: Vòng 2 lớn, chân thon → Áo suông, cổ chữ V, quần cạp cao\n'
          '• 🍐 **Quả lê (Pear)**: Hông to hơn vai → Áo có đệm vai, chân váy chữ A\n'
          '• ⏳ **Đồng hồ cát (Hourglass)**: Cân đối → Ôm sát vừa phải, nhấn eo\n'
          '• ▬ **HCN (Rectangle)**: Vai-eo-hông bằng nhau → Áo peplum, đai lưng\n\n'
          'Chị thuộc dáng nào để em gợi ý outfit phù hợp nhất nha! 💕';
    }
    if (msg.contains('mới') || msg.contains('sản phẩm')) {
      return 'Hiện tại BigStyle đang có những bộ sưu tập mới nhất:\n\n'
          '🌸 **BST Hè 2025** — Vải thoáng mát, màu pastel\n'
          '🖤 **BST Basic Đen huyền** — Mix & match dễ dàng\n'
          '💃 **BST Đầm dự tiệc** — Sang trọng, tôn dáng\n\n'
          'Chị muốn xem sản phẩm cụ thể nào không ạ? Em gửi link cho chị tham khảo nha! ✨';
    }
    if (msg.contains('đổi trả') || msg.contains('chính sách')) {
      return 'Chính sách đổi trả của BigStyle ạ? 📋\n\n'
          '✅ **Đổi hàng trong 7 ngày** (kể từ ngày nhận)\n'
          '✅ Sản phẩm còn nguyên nhãn mác, chưa qua sử dụng\n'
          '✅ **Miễn phí đổi size** lần đầu\n'
          '❌ Không hỗ trợ trả hàng hoàn tiền\n\n'
          'Nếu cần đổi hàng, chị liên hệ hotline hoặc chat với shop để được hướng dẫn chi tiết nha! 💕';
    }
    return 'Chào chị! Em là **BigStyle Bot** — trợ lý thời trang bigsize đây ạ! 🌸\n\n'
        'Em có thể giúp gì cho chị hôm nay ạ?\n\n'
        '💡 **Gợi ý cho chị:**\n'
        '• Nhấn "Tư vấn size cho tôi" để chọn size phù hợp\n'
        '• Nhấn "Outfit theo body type" để được phối đồ\n'
        '• Hoặc chị cứ hỏi em bất cứ điều gì về thời trang nha!\n\n'
        'BigStyle — Mặc đẹp không giới hạn! ✨';
  }
}
