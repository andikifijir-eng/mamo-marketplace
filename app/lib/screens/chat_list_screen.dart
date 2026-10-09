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

/// Desain Figma (365x793): header putih dengan tombol back bulat + judul "Chat"
/// + ikon search; tab "Aktif (n)" bergaris bawah biru dan "Selesai"; daftar
/// percakapan: avatar bulat berwarna, nama, info produk, cuplikan pesan, jam,
/// badge unread, divider tipis.
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  int _tab = 0; // 0 = Aktif, 1 = Selesai

  /// Warna avatar deterministik dari nama (desain: #4858E8, #8257C5).
  static const avatarColors = [
    Color(0xFF4858E8),
    Color(0xFF8257C5),
    Color(0xFF168A61),
    Color(0xFFD3454D),
  ];

  static Color avatarColor(String? name) {
    var h = 0;
    for (final c in (name ?? '').codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return avatarColors[h % avatarColors.length];
  }

  /// Percakapan dianggap "Selesai" bila order pembeli-penjual sudah tuntas.
  Set<String> _finishedKeys(WidgetRef ref) {
    final orders = <Order>[
      ...?ref.watch(ordersProvider(false)).valueOrNull,
      ...?ref.watch(ordersProvider(true)).valueOrNull,
    ];
    return {
      for (final o in orders)
        if (const ['completed', 'cancelled', 'rejected'].contains(o.status))
          '${o.buyerId}|${o.sellerId}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationsProvider);
    final finished = _finishedKeys(ref);

    return Scaffold(
      backgroundColor: MamoColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _BackHeader(title: 'Chat', trailing: _SearchAction()),
            async.when(
              loading: () => const Expanded(
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.5))),
              error: (e, _) => Expanded(
                child: ErrorState(
                  message: ApiClient.errorMessage(e),
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
              ),
              data: (list) {
                bool isDone(Conversation c) =>
                    finished.contains('${c.buyerId}|${c.sellerId}');
                final aktif = list.where((c) => !isDone(c)).toList();
                final selesai = list.where(isDone).toList();
                final items = _tab == 0 ? aktif : selesai;
                final unread = aktif.fold<int>(0, (s, c) => s + c.unreadCount);

                return Expanded(
                  child: Column(
                    children: [
                      _Tabs(
                        index: _tab,
                        aktifCount: unread,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                      Expanded(
                        child: items.isEmpty
                            ? EmptyState(
                                message: _tab == 0
                                    ? 'Belum ada percakapan aktif.\nMulai chat penjual dari halaman produk.'
                                    : 'Belum ada percakapan selesai.',
                                icon: Icons.chat_bubble_outline,
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const Divider(
                                    height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
                                itemBuilder: (c, i) => _ChatTile(
                                  conv: items[i],
                                  onTap: () => context.push('/chat/${items[i].id}',
                                      extra: items[i].otherName ?? 'Chat'),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol back bulat (d=45, border #BEC2C8) + judul + aksi kanan.
class _BackHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _BackHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => canPop ? router!.pop() : context.go('/home'),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B0B0B),
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});
  static const double size = 45;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFBEC2C8), width: 1),
        ),
        child: Icon(icon, size: size * 0.38, color: const Color(0xFF808080)),
      ),
    );
  }
}

class _SearchAction extends StatelessWidget {
  const _SearchAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push('/search'),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: const Icon(Icons.search_rounded, size: 27, color: Color(0xFF172039)),
    );
  }
}

/// Tab "Aktif (n)" / "Selesai" dengan garis bawah biru pada tab aktif.
class _Tabs extends StatelessWidget {
  final int index;
  final int aktifCount;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.index, required this.aktifCount, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, int i, {int? badge}) {
      final active = index == i;
      return GestureDetector(
        onTap: () => onChanged(i),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(left: i == 0 ? 17 : 28),
          // IntrinsicWidth: garis bawah selebar label+badge (sesuai desain),
          // bukan selebar layar — juga menghindari lebar tak terbatas di Row.
          child: IntrinsicWidth(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? MamoColors.primary : const Color(0xFF6D7485),
                    ),
                  ),
                  if (badge != null && badge > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 19),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: MamoColors.primary,
                            height: 1.1),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF5F6DEB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              tab('Aktif', 0, badge: aktifCount),
              tab('Selesai', 1),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 3),
        const Divider(height: 1, thickness: 1, color: Color(0xFFBEC1C8)),
      ],
    );
  }
}

/// Satu baris percakapan.
class _ChatTile extends StatelessWidget {
  final Conversation conv;
  final VoidCallback onTap;
  const _ChatTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _ChatListScreenState.avatarColor(conv.otherName);
    final unread = conv.unreadCount > 0;
    final name = conv.otherName ?? 'Pengguna';
    final hasAvatar = conv.otherAvatar != null && conv.otherAvatar!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 19, 22, 19),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                image: hasAvatar
                    ? DecorationImage(image: NetworkImage(conv.otherAvatar!), fit: BoxFit.cover)
                    : null,
              ),
              child: hasAvatar
                  ? null
                  : Center(
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B0B0B),
                          height: 1.1)),
                  const SizedBox(height: 4),
                  Text(
                    conv.productName ?? 'Tanpa produk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: unread ? MamoColors.primary : const Color(0xFF6D7485),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv.lastMessage ?? 'Belum ada pesan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6D7485), height: 1.15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _shortTime(conv.lastMessageAt),
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF6D7485), height: 1.1),
                ),
                if (unread) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: MamoColors.primary, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        conv.unreadCount > 9 ? '9+' : '${conv.unreadCount}',
                        style: const TextStyle(
                            fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "10:42" hari ini, "Kemarin", "n hari", atau "d Mmm".
  static String _shortTime(DateTime? dt) {
    if (dt == null) return '';
    final l = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(l.year, l.month, l.day);
    final diff = today.difference(d).inDays;
    if (diff <= 0) {
      return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '$diff hari';
    const bulan = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${l.day} ${bulan[l.month - 1]}';
  }
}
