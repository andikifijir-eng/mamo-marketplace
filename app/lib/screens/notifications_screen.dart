import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Desain Figma (361x786): header putih tombol back bulat + judul "Notifikasi"
/// + aksi teks "Tandai dibaca" biru; heading seksi "TERBARU"; item notifikasi
/// dengan ikon kotak berwarna, judul, deskripsi, waktu di kanan, notifikasi
/// belum dibaca bertitik biru dan berlatar #FAFAFF.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  /// Ikon + warna kotak per tipe (desain: chat biru, listing hijau, harga merah).
  static ({IconData icon, Color fg, Color bg}) _style(String type) {
    switch (type) {
      case 'order':
        return (icon: Icons.receipt_long_outlined, fg: const Color(0xFFD3454D), bg: const Color(0xFFFFF0F0));
      case 'chat':
        return (icon: Icons.chat_bubble_outline, fg: const Color(0xFF4858E8), bg: const Color(0xFFEEF0FF));
      case 'verification':
        return (icon: Icons.verified_user_outlined, fg: const Color(0xFF168A61), bg: const Color(0xFFE8F7F1));
      case 'listing':
        return (icon: Icons.storefront_outlined, fg: const Color(0xFF168A61), bg: const Color(0xFFE8F7F1));
      case 'price':
        return (icon: Icons.trending_down_rounded, fg: const Color(0xFFD3454D), bg: const Color(0xFFFFF0F0));
      default:
        return (icon: Icons.notifications_none, fg: const Color(0xFF4858E8), bg: const Color(0xFFEEF0FF));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => canPop ? router!.pop() : context.go('/home'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFBEC2C8)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 17, color: Color(0xFF808080)),
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Text('Notifikasi',
                        style: TextStyle(
                            fontSize: 19.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B0B0B),
                            letterSpacing: -0.2)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(notificationRepoProvider).markAllRead();
                      ref.invalidate(notificationsProvider);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Tandai dibaca',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: MamoColors.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                error: (e, _) => ErrorState(
                  message: ApiClient.errorMessage(e),
                  onRetry: () => ref.invalidate(notificationsProvider),
                ),
                data: (data) {
                  if (data.items.isEmpty) {
                    return const EmptyState(
                        message: 'Belum ada notifikasi', icon: Icons.notifications_none);
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(notificationsProvider),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(22, 8, 22, 10),
                          child: Text('TERBARU',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF6D7485))),
                        ),
                        for (var i = 0; i < data.items.length; i++) ...[
                          _NotificationTile(
                            n: data.items[i],
                            onTap: () async {
                              if (!data.items[i].isRead) {
                                await ref.read(notificationRepoProvider).markRead(data.items[i].id);
                                ref.invalidate(notificationsProvider);
                              }
                            },
                          ),
                          if (i != data.items.length - 1)
                            const Divider(
                                height: 1, thickness: 1, indent: 0, color: Color(0xFFE9E9EC)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris notifikasi. Belum dibaca: latar #FAFAFF + titik biru di kanan.
class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = NotificationsScreen._style(n.type);
    final unread = !n.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? const Color(0xFFFAFAFF) : Colors.white,
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(s.icon, size: 19, color: s.fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B0B0B),
                          height: 1.2)),
                  const SizedBox(height: 3),
                  Text(n.body ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF6D7485), height: 1.25)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeAgo(n.createdAt),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D7485))),
                if (unread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: MamoColors.primary, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    final l = dt.toLocal();
    const bulan = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${l.day} ${bulan[l.month - 1]}';
  }
}
