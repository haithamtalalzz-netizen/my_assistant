import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../core/l10n.dart';
import '../data/secret_notes_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';

/// خزنة ملاحظات سرية — الوصول ورا البصمة. (الوصول محمي بالبصمة؛ الملاحظات
/// نفسها متخزّنة محليًا في نفس قاعدة البيانات.)
class SecretNotesScreen extends StatefulWidget {
  const SecretNotesScreen({super.key});

  @override
  State<SecretNotesScreen> createState() => _SecretNotesScreenState();
}

class _SecretNotesScreenState extends State<SecretNotesScreen> {
  final _auth = LocalAuthentication();
  final _repo = SecretNotesRepo();
  bool _authed = false;
  bool _checking = true;
  List<SecretNote> _items = [];

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
        localizedReason: tr('افتح الخزنة السرية', 'Unlock secret vault'),
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException catch (e) {
      dev.log('فشل فتح الخزنة السرية', error: e);
    }
    if (!mounted) return;
    if (ok) {
      _items = await _repo.all();
    }
    setState(() {
      _authed = ok;
      _checking = false;
    });
  }

  Future<void> _reload() async {
    _items = await _repo.all();
    if (mounted) setState(() {});
  }

  Future<void> _form([SecretNote? note]) async {
    final title = TextEditingController(text: note?.title ?? '');
    final body = TextEditingController(text: note?.body ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note == null
            ? tr('ملاحظة سرية جديدة', 'New secret note')
            : tr('تعديل', 'Edit')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: note == null,
                decoration:
                    InputDecoration(labelText: tr('العنوان', 'Title')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                maxLines: 5,
                decoration: InputDecoration(
                    labelText: tr('التفاصيل (أرقام حسابات، شفرات...)',
                        'Details (account numbers, codes...)'),
                    alignLabelWithHint: true),
              ),
            ],
          ),
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
    if (saved == true && title.text.trim().isNotEmpty) {
      await _repo.save(SecretNote(
        id: note?.id,
        title: title.text.trim(),
        body: body.text.trim(),
        createdAt: note?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      await _reload();
    }
    title.dispose();
    body.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('الخزنة السرية', 'Secret vault'))),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : !_authed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 56, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(tr('محتاج بصمتك عشان تفتح الخزنة',
                          'Fingerprint required to open the vault')),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _unlock,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(tr('افتح', 'Unlock')),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? EmptyHint(
                      icon: Icons.shield_outlined,
                      text: tr('احفظ أرقامك وشفراتك السرية هنا ورا البصمة',
                          'Keep your secret numbers & codes here behind fingerprint'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final n = _items[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: ListTile(
                            leading: const Icon(Icons.vpn_key_outlined),
                            title: Text(n.title),
                            subtitle: n.body.isEmpty
                                ? null
                                : Text(n.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () async {
                                if (!await confirmDelete(
                                    context, tr('«${n.title}»', '"${n.title}"'))) {
                                  return;
                                }
                                await _repo.delete(n.id!);
                                await _reload();
                              },
                            ),
                            onTap: () => _form(n),
                          ),
                        );
                      },
                    ),
      floatingActionButton: _authed
          ? FloatingActionButton(
              heroTag: 'secret_fab',
              onPressed: () => _form(),
              tooltip: tr('ملاحظة جديدة', 'New note'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
