import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Chat realtime buyer <-> seller via WebSocket backend (/ws).
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
      final wsUrl = '${const String.fromEnvironment('MAMO_WS', defaultValue: 'ws://localhost:4000')}/ws?token=$token';
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
    } catch (_) {
      // Realtime opsional: chat tetap jalan via REST kalau WS gagal.
    }
  }

  Future<void> _load() async {
    try {
      final msgs = await ref.read(chatRepoProvider).messages(widget.conversationId);
      if (!mounted) return;
      setState(() { _messages = msgs; _loading = false; });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnack(context, ApiClient.errorMessage(e), error: true);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName ?? 'Chat', style: const TextStyle(fontSize: 15)),
            const Text('Penjual / Pembeli',
                style: TextStyle(fontSize: 11, color: MamoColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : _messages.isEmpty
                    ? const EmptyState(
                        message: 'Mulai percakapan.\nTanya kondisi barang atau nego harga.',
                        icon: Icons.chat_bubble_outline,
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
                                  maxWidth: MediaQuery.of(context).size.width * 0.72),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: mine ? MamoColors.primary : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(MamoRadius.lg),
                                  topRight: const Radius.circular(MamoRadius.lg),
                                  bottomLeft: Radius.circular(mine ? MamoRadius.lg : 4),
                                  bottomRight: Radius.circular(mine ? 4 : MamoRadius.lg),
                                ),
                                border: mine ? null : Border.all(color: MamoColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(m.message,
                                      style: TextStyle(
                                          fontSize: 13.5,
                                          height: 1.4,
                                          color: mine ? Colors.white : MamoColors.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(
                                    m.createdAt != null ? df.format(m.createdAt!.toLocal()) : '',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: mine ? Colors.white70 : MamoColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: MamoColors.cardBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(MamoRadius.md)),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
