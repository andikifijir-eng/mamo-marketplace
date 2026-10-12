import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Screen Chat Penjual sesuai target desain Figma & screenshot referensi:
/// 1. Top Bar Gabungan: Card putih rounded bawah (radius 24) berbayang tipis:
///    - Baris atas: Tombol back bulat, avatar squircle biru (radius 14) + icon user putih,
///      nama penjual bold hitam, dot hijau + status "Online", tombol more titik tiga bulat.
///    - Baris bawah: Mini product info langsung di atas latar putih (thumbnail produk MacBook,
///      nama "MacBook Air M1 2020", harga biru bold "Rp8.250.000", tombol outline rounded "Lihat").
/// 2. Body Chat: Latar abu-abu sangat muda (#F7F7F9), kosong bersih jika belum ada riwayat chat.
/// 3. Baris Input Bawah: Card putih rounded atas (radius 24):
///    - Tombol (+) bulat bergaris tepi hitam solid.
///    - Textfield abu-abu terang (#F3F4F6) bergaris tepi tipis (#E5E7EB), rounded 12.
///    - Tombol kirim squircle biru (#4355F9) dengan icon pesawat kertas putih.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? otherName;
  final String? productName;
  final int? productPrice;
  final String? productImage;
  final String? productId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherName,
    this.productName,
    this.productPrice,
    this.productImage,
    this.productId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _myId;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  static const _blue = Color(0xFF4355F9);
  static final _rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myId = await SessionStore.userId;
    await _load();
    _connectWs();
  }

  void _connectWs() async {
    final token = await SessionStore.token;
    if (token == null) return;
    try {
      final wsUrl =
          '${const String.fromEnvironment('MAMO_WS', defaultValue: 'ws://localhost:4000')}/ws?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _sub = _channel!.stream.listen((raw) {
        try {
          final data = jsonDecode(raw as String);
          if (data['type'] == 'chat:message' &&
              data['conversationId'] == widget.conversationId) {
            final msg = ChatMessage.fromJson(data['message']);
            if (mounted) {
              setState(() => _messages.add(msg));
              _scrollToEnd();
            }
          }
        } catch (_) {}
      }, onError: (_) {}, onDone: () {});
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final msgs = await ref.read(chatRepoProvider).messages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await ref.read(chatRepoProvider).send(widget.conversationId, text);
      _input.clear();
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToEnd();
      }
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('HH:mm');
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    final pName = widget.productName ?? 'MacBook Air M1 2020';
    final pPrice = widget.productPrice ?? 8250000;
    final pImg = widget.productImage ??
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800';
    final pId = widget.productId ?? 'p1';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Card Gabungan (Header + Mini Product Card) ────
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  // Baris Atas: Tombol Back, Avatar Squircle, Info Penjual, More
                  Row(
                    children: [
                      _circleBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          if (canPop) {
                            router!.pop();
                          } else {
                            context.go('/chat');
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      // Avatar Squircle Biru (radius 14)
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_rounded, size: 24, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      // Nama Penjual & Status Online
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.otherName ?? 'Nama Penjual',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _circleBtn(
                        icon: Icons.more_horiz_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Baris Bawah: Mini Product Card langsung di latar putih
                  Row(
                    children: [
                      // Thumbnail MacBook
                      ProductImageBox(
                        url: pImg,
                        width: 48,
                        height: 48,
                        radius: 10,
                      ),
                      const SizedBox(width: 12),
                      // Judul & Harga Biru Bold
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _rp.format(pPrice),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Tombol "Lihat"
                      OutlinedButton(
                        onPressed: () => context.push('/product/$pId'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Lihat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── 2. Chat Messages Body ────────────────────────────────
            Expanded(
              child: _loading
                  ? const SizedBox.shrink()
                  : _messages.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (c, i) {
                            final m = _messages[i];
                            final mine = m.senderId == _myId;
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: mine ? _blue : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(mine ? 16 : 4),
                                    bottomRight: Radius.circular(mine ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      m.message,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        height: 1.4,
                                        color: mine ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      m.createdAt != null ? df.format(m.createdAt!.toLocal()) : '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: mine ? Colors.white70 : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // ── 3. Baris Input Bawah ─────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tombol (+) Bulat dengan Outline Hitam
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF111827), width: 1.5),
                    ),
                    child: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF111827)),
                  ),
                  const SizedBox(width: 10),

                  // Field Input Teks Rounded 12px
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tombol Kirim Squircle Biru Solid
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _sending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 17, color: const Color(0xFF1F2937)),
      ),
    );
  }
}
