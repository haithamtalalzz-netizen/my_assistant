import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/gemini.dart';
import '../../core/l10n.dart';
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
  bool _loading = true;
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
    setState(() {
      _hasKey = hasKey;
      _loading = false;
    });
  }

  Future<void> _saveKey() async {
    final key = _keyInput.text.trim();
    if (key.isEmpty) return;
    await SettingsRepo().set('gemini_key', key);
    if (!mounted) return;
    setState(() => _hasKey = true);
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

    final context = await buildBrainContext();
    // آخر ٦ رسائل كسياق محادثة.
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
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
          false, answer ?? tr('مفيش مفتاح متسجل.', 'No API key set.')));
      _sending = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Widget _setupView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.chat_bubble_outline, size: 48, color: scheme.primary),
        const SizedBox(height: 16),
        Text(tr('فعّل محادثة المدير — ببلاش', 'Enable manager chat — free'),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(
          tr(
              '١. افتح aistudio.google.com من الزرار تحت\n'
                  '٢. سجل بحساب جوجل بتاعك (من غير أي كارت دفع)\n'
                  '٣. دوس «Get API key» وانسخ المفتاح\n'
                  '٤. الصقه هنا وخلاص',
              '1. Open aistudio.google.com from the button below\n'
                  '2. Sign in with your Google account (no payment card)\n'
                  '3. Tap "Get API key" and copy the key\n'
                  '4. Paste it here and you\'re done'),
          style: const TextStyle(height: 2),
        ),
        const SizedBox(height: 8),
        Text(
          tr(
              'ملحوظة خصوصية: في المستوى المجاني جوجل ممكن تستخدم المحادثات '
                  'لتحسين نماذجها. تقدر تتحكم في اللي بيتبعت من الإعدادات '
                  '(مشاركة بيانات الصحة مثلًا).',
              'Privacy note: on the free tier Google may use conversations to '
                  'improve its models. You can control what gets sent from settings '
                  '(sharing health data, for example).'),
          style: TextStyle(color: scheme.outline, fontSize: 13, height: 1.7),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => launchUrl(
              Uri.parse('https://aistudio.google.com/apikey'),
              mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new),
          label: Text(tr('افتح صفحة المفتاح', 'Open the API key page')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keyInput,
          decoration:
              InputDecoration(labelText: tr('الصق المفتاح هنا', 'Paste the key here')),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _saveKey, child: Text(tr('تفعيل', 'Enable'))),
      ],
    );
  }

  Widget _chatView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr(
                          'اسأل عن أي حاجة في بياناتك:\n«صرفت كام على الأكل الشهر ده؟»\n«إيه أهم حاجة أعملها بكرة؟»\n«اديني نصيحة من أرقامي»',
                          'Ask anything about your data:\n"How much did I spend on food this month?"\n"What\'s the most important thing to do tomorrow?"\n"Give me advice from my numbers"'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline, height: 2),
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
                                MediaQuery.of(context).size.width * 0.8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('اسأل مديرك', 'Ask your manager'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasKey
              ? _chatView(context)
              : _setupView(context),
    );
  }
}
