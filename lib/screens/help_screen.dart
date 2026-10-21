import 'package:flutter/material.dart';
import '../help_agent.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _agent = HelpAgent.create();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;

  static const _quick = [
    'Tiket tidak muncul',
    'Pembayaran gagal',
    'Barcode tidak terbaca',
    'Refund / batalkan tiket',
    'Cara pakai voucher',
  ];

  @override
  void initState() {
    super.initState();
    AppState.I.seedChat(
        'Halo ${AppState.I.username}! Aku TikTap Assistant. Ada kendala apa dengan pesanan atau aplikasinya? Ceritakan saja, atau pilih topik di bawah.');
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _typing) return;
    _input.clear();
    AppState.I.addChat(ChatMsg(fromUser: true, text: t));
    setState(() => _typing = true);
    _scrollDown();
    String answer;
    try {
      answer = await _agent.reply(t, AppState.I.chat);
    } catch (_) {
      answer =
          'Maaf, ada gangguan saat menjawab. Coba lagi sebentar atau hubungi $supportEmail.';
    }
    AppState.I.addChat(ChatMsg(fromUser: false, text: answer));
    if (!mounted) return;
    setState(() => _typing = false);
    _scrollDown();
  }

  Widget _bubble(ChatMsg m) {
    final me = m.fromUser;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: me ? null : Colors.white.withValues(alpha: 0.12),
          gradient: me
              ? const LinearGradient(
                  colors: [Color(0xFF0B6BA8), Color(0xFF2F86E0)])
              : null,
          border: me ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(me ? 16 : 4),
            bottomRight: Radius.circular(me ? 4 : 16),
          ),
        ),
        child: Text(m.text, style: const TextStyle(fontSize: 14, height: 1.35)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Bantuan',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.support_agent, size: 16, color: AppColors.lightBlue),
            const SizedBox(width: 6),
            Text('TikTap Assistant  •  ${_agent.label}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: AppState.I,
            builder: (context, _) {
              final chat = AppState.I.chat;
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: chat.length + (_typing ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i < chat.length) return _bubble(chat[i]);
                  return const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text('TikTap Assistant sedang mengetik...',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quick.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _send(_quick[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.6)),
                ),
                child: Text(_quick[i], style: const TextStyle(fontSize: 12.5)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: GlassBox(
            padding: const EdgeInsets.only(left: 16, right: 6),
            radius: 24,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: _send,
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Tulis kendalamu...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              IconButton(
                onPressed: _typing ? null : () => _send(_input.text),
                icon: Icon(Icons.send_rounded,
                    color: _typing ? Colors.white30 : AppColors.lightBlue),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
