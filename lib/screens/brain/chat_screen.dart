import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/gemini.dart';
import '../../core/l10n.dart';
import '../../core/local_brain.dart';
import '../../data/brain_context.dart';
import '../../data/settings_repo.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  final bool fromUser;
  final String text;

  const _ChatMessage(this.fromUser, this.text);
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _keyInput = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _hasKey = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _input.dispose();
    _keyInput.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final hasKey = await GeminiClient.hasKey();
    if (!mounted) return;
    setState(() => _hasKey = hasKey);
  }

  Future<void> _saveKey() async {
    final key = _keyInput.text.trim();
    if (key.isEmpty) return;
    await SettingsRepo().set('gemini_key', key);
    if (!mounted) return;
    setState(() => _hasKey = true);
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('اتفعّل Gemini للأسئلة المفتوحة ✅',
            'Gemini enabled for open questions ✅'))));
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _messages.add(_ChatMessage(true, question));
      _sending = true;
    });
    _scrollDown();

    // ١) العقل المحلي المجاني الأول.
    final local = await LocalBrain.answer(question);
    String reply;
    if (local.handled) {
      reply = local.text;
    } else if (_hasKey) {
      // ٢) سؤال مفتوح + المستخدم مفعّل Gemini → نبعته.
      final context = await buildBrainContext();
      final history = _messages.length <= 1
          ? ''
          : _messages
              .sublist(0, _messages.length - 1)
              .skip(_messages.length > 7 ? _messages.length - 7 : 0)
              .map((m) => '${m.fromUser ? 'المستخدم' : 'المدير'}: ${m.text}')
              .join('\n');
      final answer = await GeminiClient.ask(
        system: '$kBrainSystemPrompt\n\nبيانات المستخدم الحالية:\n$context',
        question: history.isEmpty
            ? question
            : 'المحادثة السابقة:\n$history\n\nالسؤال الجديد: $question',
      );
      reply = answer ?? LocalBrain.helpText();
    } else {
      // ٣) سؤال مفتوح من غير مفتاح → مساعدة + اقتراح تفعيل Gemini.
      reply = '${tr('مش متأكد من السؤال ده. ', "I'm not sure about that one. ")}'
          '${LocalBrain.helpText()}\n\n'
          '${tr('وللأسئلة المفتوحة تقدر تفعّل Gemini المجاني من زر ✨ فوق.', 'For open-ended questions, enable free Gemini from the ✨ button above.')}';
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(false, reply));
      _sending = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _openGeminiSetup() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 4,
            right: 4),
        child: _geminiSetup(ctx),
      ),
    );
  }

  Widget _geminiSetup(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.auto_awesome, size: 44, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
            tr('ميزة إضافية اختيارية: Gemini للأسئلة المفتوحة — ببلاش',
                'Optional extra: Gemini for open questions — free'),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          tr(
              'مديرك بيرد على كل أسئلة بياناتك مجانًا من غير أي إعداد. لو عايز '
                  'كمان يرد على أسئلة عامة ومفتوحة، فعّل Gemini المجاني:\n'
                  '١. افتح aistudio.google.com من الزر تحت\n'
                  '٢. سجّل بحساب جوجل (من غير كارت دفع)\n'
                  '٣. دوس «Get API key» وانسخ المفتاح\n'
                  '٤. الصقه هنا',
              'Your manager already answers all your data questions for free with '
                  'no setup. To also answer general open-ended questions, enable '
                  'free Gemini:\n'
                  '1. Open aistudio.google.com below\n'
                  '2. Sign in with Google (no payment card)\n'
                  '3. Tap "Get API key" and copy it\n'
                  '4. Paste it here'),
          style: const TextStyle(height: 1.9),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse('https://aistudio.google.com/apikey'),
              mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new),
          label: Text(tr('افتح صفحة المفتاح', 'Open the API key page')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keyInput,
          decoration: InputDecoration(
              labelText: tr('الصق المفتاح هنا', 'Paste the key here')),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _saveKey, child: Text(tr('تفعيل', 'Enable'))),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('اسأل مديرك', 'Ask your manager')),
        actions: [
          IconButton(
            tooltip: tr('أسئلة مفتوحة (Gemini)', 'Open questions (Gemini)'),
            onPressed: _openGeminiSetup,
            icon: Icon(_hasKey ? Icons.auto_awesome : Icons.auto_awesome_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        LocalBrain.helpText(),
                        style: TextStyle(color: scheme.outline, height: 1.9),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.fromUser
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.82),
                          decoration: BoxDecoration(
                            color: m.fromUser
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(m.text,
                              style: const TextStyle(height: 1.6)),
                        ),
                      );
                    },
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: InputDecoration(
                          hintText: tr('اسأل مديرك...', 'Ask your manager...')),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
