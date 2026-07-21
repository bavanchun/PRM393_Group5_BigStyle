import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../blocs/support_chat/support_chat_bloc.dart';
import '../../../blocs/support_inbox/support_inbox_bloc.dart';
import '../../../blocs/support_inbox/support_inbox_event.dart';
import '../../../blocs/support_inbox/support_inbox_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/support_conversation_model.dart';
import '../../../services/support_chat_service.dart';
import '../../../widgets/app_error_state.dart';
import '../../chat/support_chat_screen.dart';

/// Staff inbox: live list of support conversations sorted by last activity,
/// each with a denormalized unread badge. Opening a thread provides a fresh
/// screen-scoped [SupportChatBloc].
class ManagerSupportInboxScreen extends StatelessWidget {
  const ManagerSupportInboxScreen({super.key});

  void _openThread(BuildContext context, SupportConversationModel conv) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => SupportChatBloc(SupportChatService()),
          child: SupportChatScreen(
            conversationId: conv.id,
            title: 'Khách hàng',
          ),
        ),
      ),
    );
  }

  void _retry(BuildContext context) {
    context.read<SupportInboxBloc>().add(const SupportInboxSubscribe());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: BlocConsumer<SupportInboxBloc, SupportInboxState>(
        // Surface transient stream failures that keep the list intact; the
        // empty-list case is handled by the full-screen error state below.
        listenWhen: (previous, current) =>
            current.error != null &&
            current.error != previous.error &&
            current.conversations.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        builder: (context, state) {
          if (state.isLoading && state.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.conversations.isEmpty) {
            return Center(
              child: AppErrorState(
                message: state.error!,
                onRetry: () => _retry(context),
              ),
            );
          }
          if (state.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có cuộc trò chuyện nào',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: state.conversations.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final conv = state.conversations[index];
              return _tile(context, conv);
            },
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, SupportConversationModel conv) {
    final hasUnread = conv.unreadForStaff > 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.person, color: AppColors.primary),
      ),
      title: Text(
        'Khách hàng',
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        conv.lastMessagePreview ?? 'Chưa có tin nhắn',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('HH:mm').format(conv.lastMessageAt),
            style: AppTypography.caption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conv.unreadForStaff}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _openThread(context, conv),
    );
  }
}
