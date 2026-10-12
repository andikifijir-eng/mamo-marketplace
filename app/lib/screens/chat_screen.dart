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

/// Screen Chat Penjual sesuai target desain Figma (figma-screen-chat-seller.png):
/// 1. Top bar: Tombol back bulat (border abu tipis), avatar bulat biru + icon user putih,
///    nama penjual bold hitam, status dot hijau + "Online", action titik tiga bulat kanan.
/// 2. Mini product card di atas: floating card putih rounded shadow tipis (thumbnail produk,
///    nama barang "MacBook Air M1 2020", harga tebal biru "Rp8.250.000", tombol outline "Lihat").
/// 3. Riwayat pesan / bubbles (background #F7F7F9).
/// 4. Baris input bawah: tombol (+) di kiri, pill input text field abu-abu terang,
///    tombol kirim squircle biru dengan icon pesawat kertas putih.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? otherName;

  const ChatScreen({super.key, required this.conversationId, this.otherName});

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Mock pesan demo jika percakapan belum tersimpan di DB
        if (_messages.isEmpty) {
          _messages = [
            ChatMessage(
              id: 'm1',
              senderId: 'seller',
              message: 'Halo! Ada yang bisa saya bantu untuk MacBook Air ini?',
              createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            ChatMessage(
              id: 'm2',
              senderId: _myId ?? 'buyer',
              message: 'Halo kak, apakah barangnya masih ready dan bisa COD di area Tembalang?',
              createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
            ),
          ];
        }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Bar Custom (Back, Avatar, Nama, Online, More) ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
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
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  // Nama & Status Online
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
            ),

            // ── 2. Mini Product Card di Atas Chat ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MacBook Air M1 2020',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Rp8.250.000',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        'Lihat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Chat Messages Body ────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Mulai percakapan dengan penjual...',
                            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          ),
                        )
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

            // ── 4. Input Baris Bawah ─────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tombol (+)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(width: 10),

                  // Pill Text Field
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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

                  // Tombol Kirim Squircle Biru
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
