import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_conversation_model.dart';
import '../models/support_message_model.dart';

/// Human support chat data access. All conversation mutations go through
/// SECURITY DEFINER RPCs; clients only SELECT/INSERT and subscribe to Realtime.
class SupportChatService {
  final SupabaseClient _client;

  SupportChatService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Returns the caller's single conversation, creating it if absent (RPC).
  Future<SupportConversationModel> getOrCreateConversation() async {
    final data = await _client.rpc('get_or_create_my_conversation');
    final map = data is List ? data.first : data;
    return SupportConversationModel.fromMap(map as Map<String, dynamic>);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    await _client.from('support_messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    });
  }

  /// Live ordered message stream for one conversation.
  Stream<List<SupportMessageModel>> messagesStream(String conversationId) {
    return _client
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map(SupportMessageModel.fromMap).toList());
  }

  /// Live staff inbox stream. Unread + preview come denormalized from the row
  /// (no per-conversation count queries).
  Stream<List<SupportConversationModel>> conversationsStream() {
    return _client
        .from('support_conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((rows) => rows.map(SupportConversationModel.fromMap).toList());
  }

  Future<void> markRead(String conversationId) async {
    await _client.rpc(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }
}
