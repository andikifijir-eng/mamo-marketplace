import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final myId = await SessionStore.userId;
  return ref.read(chatRepoProvider).conversations(myId ?? '');
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              message: 'Belum ada percakapan.\nMulai chat penjual dari halaman produk.',
              icon: Icons.chat_bubble_outline,
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (c, i) {
              final conv = list[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: MamoColors.infoBg,
                  backgroundImage: (conv.otherAvatar != null && conv.otherAvatar!.isNotEmpty)
                      ? NetworkImage(conv.otherAvatar!)
                      : null,
                  child: (conv.otherAvatar == null || conv.otherAvatar!.isEmpty)
                      ? Text((conv.otherName ?? 'U').characters.first.toUpperCase(),
                          style: const TextStyle(
                              color: MamoColors.primary, fontWeight: FontWeight.w700))
                      : null,
                ),
                title: Text(conv.otherName ?? 'Pengguna',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  conv.lastMessage ?? 'Belum ada pesan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: MamoColors.textSecondary),
                ),
                trailing: conv.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: const BoxDecoration(
                            color: MamoColors.primary, shape: BoxShape.circle),
                        child: Text('${conv.unreadCount}',
                            style: const TextStyle(fontSize: 10, color: Colors.white)),
                      )
                    : null,
                onTap: () => context.push('/chat/${conv.id}',
                    extra: conv.otherName ?? 'Chat'),
              );
            },
          );
        },
      ),
    );
  }
}
