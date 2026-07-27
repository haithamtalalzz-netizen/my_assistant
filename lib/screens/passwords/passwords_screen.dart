import '../../core/log.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/password_tools.dart';
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
      logError('فشل فتح كلمات السر', e);
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
                  : Builder(builder: (context) {
                      final audit = auditPasswords({
                        for (final e in _items)
                          if (e.id != null && e.secret.isNotEmpty)
                            e.id!: e.secret,
                      });
                      final reused = {
                        for (final g in audit.reusedGroups) ...g,
                      };
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                        children: [
                          if (!audit.isClean) _auditBanner(audit, scheme),
                          for (final e in _items)
                            _tile(e, scheme,
                                weak: audit.weakIds.contains(e.id),
                                reused: reused.contains(e.id)),
                        ],
                      );
                    }),
      floatingActionButton: _authed
          ? FloatingActionButton(
              onPressed: () => _form(),
              tooltip: tr('كلمة سر جديدة', 'New password'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// بانر تدقيق: عدد الضعيفة والمكرَّرة.
  Widget _auditBanner(PasswordAudit audit, ColorScheme scheme) {
    final parts = <String>[
      if (audit.weakIds.isNotEmpty)
        tr('${arNum(audit.weakIds.length)} ضعيفة',
            '${audit.weakIds.length} weak'),
      if (audit.reusedGroups.isNotEmpty)
        tr('${arNum(audit.reusedCount)} مكرَّرة',
            '${audit.reusedCount} reused'),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.gpp_maybe_outlined, color: scheme.error, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tr('كلمات سر محتاجة تقوية: ${parts.join(' · ')}',
                'Passwords need attention: ${parts.join(' · ')}'),
            style: TextStyle(
                color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _tile(PasswordEntry e, ColorScheme scheme,
      {bool weak = false, bool reused = false}) {
    final shown = _revealed.contains(e.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        title: Row(children: [
          Flexible(
            child: Text(e.label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (weak) ...[
            const SizedBox(width: 8),
            _chip(tr('ضعيفة', 'weak'), scheme.error),
          ],
          if (reused) ...[
            const SizedBox(width: 6),
            _chip(tr('مكرَّرة', 'reused'), Colors.orange),
          ],
        ]),
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
                decoration: InputDecoration(
                  labelText: tr('كلمة السر', 'Password'),
                  suffixIcon: IconButton(
                    tooltip: tr('توليد كلمة قوية', 'Generate strong password'),
                    icon: const Icon(Icons.casino_outlined),
                    onPressed: () => secret.text = generatePassword(),
                  ),
                )),
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
