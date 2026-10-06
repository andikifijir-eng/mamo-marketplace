import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) {
    switch (type) {
      case 'order': return Icons.receipt_long_outlined;
      case 'chat': return Icons.chat_bubble_outline;
      case 'verification': return Icons.verified_user_outlined;
      case 'listing': return Icons.storefront_outlined;
      default: return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final df = DateFormat('d MMM, HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepoProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Tandai semua'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return const EmptyState(
              message: 'Belum ada notifikasi',
              icon: Icons.notifications_none,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              itemCount: data.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (c, i) {
                final n = data.items[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: n.isRead ? const Color(0xFFF1F5F9) : MamoColors.infoBg,
                      borderRadius: BorderRadius.circular(MamoRadius.md),
                    ),
                    child: Icon(_icon(n.type), size: 20,
                        color: n.isRead ? MamoColors.textMuted : MamoColors.primary),
                  ),
                  title: Text(n.title,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700)),
                  subtitle: Text(n.body ?? '',
                      style: const TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
                  trailing: Text(
                    n.createdAt != null ? df.format(n.createdAt!.toLocal()) : '',
                    style: const TextStyle(fontSize: 10, color: MamoColors.textMuted),
                  ),
                  onTap: () async {
                    if (!n.isRead) {
                      await ref.read(notificationRepoProvider).markRead(n.id);
                      ref.invalidate(notificationsProvider);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
