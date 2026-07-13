import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/l10n.dart';
import '../../data/passwords_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// كلمات السر — الوصول محمى بالبصمة (زى الخزنة السرية: قفل وصول، مش تشفير).
class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({super.key});

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  final _auth = LocalAuthentication();
  final _repo = PasswordsRepo();
  bool _authed = false;
  bool _checking = true;
  List<PasswordEntry> _items = [];
  final Set<int> _revealed = {};

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    setState(() => _checking = true);
    var ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason: tr('افتح كلمات السر', 'Unlock passwords'),
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException catch (e) {
      dev.log('فشل فتح كلمات السر', error: e);
    }
    if (!mounted) return;
    if (ok) _items = await _repo.all();
    setState(() {
      _authed = ok;
      _checking = false;
    });
  }

  Future<void> _reload() async {
    _items = await _repo.all();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('كلمات السر', 'Passwords'))),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : !_authed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 56, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(tr('محمى بالبصمة', 'Protected by fingerprint')),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                          onPressed: _unlock,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(tr('افتح', 'Unlock'))),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.key_outlined,
                          text: tr('ضيف كلمة سر بزرار +', 'Add a password with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [for (final e in _items) _tile(e, scheme)],
                    ),
      floatingActionButton: _authed
          ? FloatingActionButton(
              onPressed: () => _form(),
              tooltip: tr('كلمة سر جديدة', 'New password'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _tile(PasswordEntry e, ColorScheme scheme) {
    final shown = _revealed.contains(e.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        title: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.username.isNotEmpty) Text(e.username),
            Row(
              children: [
                Expanded(
                  child: Text(shown ? e.secret : '••••••••',
                      style: const TextStyle(letterSpacing: 1.5)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(shown ? Icons.visibility_off : Icons.visibility,
                      size: 18),
                  onPressed: () => setState(() {
                    if (shown) {
                      _revealed.remove(e.id);
                    } else {
                      _revealed.add(e.id!);
                    }
                  }),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: e.secret));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(tr('اتنسخت ✓', 'Copied ✓'))));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') await _form(e);
            if (v == 'delete') {
              await _repo.delete(e.id!);
              await _reload();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
      ),
    );
  }

  Future<void> _form([PasswordEntry? entry]) async {
    final label = TextEditingController(text: entry?.label ?? '');
    final username = TextEditingController(text: entry?.username ?? '');
    final secret = TextEditingController(text: entry?.secret ?? '');
    final url = TextEditingController(text: entry?.url ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(entry == null ? tr('كلمة سر جديدة', 'New password') : tr('تعديل', 'Edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: label,
                autofocus: entry == null,
                decoration: InputDecoration(
                    labelText: tr('الاسم (جيميل، بنك…)', 'Label (Gmail, bank…)'))),
            const SizedBox(height: 8),
            TextField(
                controller: username,
                decoration: InputDecoration(
                    labelText: tr('اسم المستخدم/الإيميل', 'Username / email'))),
            const SizedBox(height: 8),
            TextField(
                controller: secret,
                decoration:
                    InputDecoration(labelText: tr('كلمة السر', 'Password'))),
            const SizedBox(height: 8),
            TextField(
                controller: url,
                decoration: InputDecoration(labelText: tr('الموقع (اختيارى)', 'URL (optional)'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );

    if (saved == true && label.text.trim().isNotEmpty) {
      await _repo.save(PasswordEntry(
        id: entry?.id,
        label: label.text.trim(),
        username: username.text.trim(),
        secret: secret.text,
        url: url.text.trim(),
        notes: entry?.notes ?? '',
        createdAt: entry?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      await _reload();
    }
    label.dispose();
    username.dispose();
    secret.dispose();
    url.dispose();
  }
}
