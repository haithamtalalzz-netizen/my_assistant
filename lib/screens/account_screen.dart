import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../data/settings_repo.dart';
import 'lock_gate.dart';
import 'onboarding_gate.dart';
import 'shell.dart';

/// صفحة الحساب — حاليًا حساب محلي على الجهاز (اسم + إيميل).
/// تسجيل الدخول بالإيميل وتأكيده عبر رسالة قيد الإعداد (يحتاج خادم/Firebase).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _settings = SettingsRepo();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _settings.userName();
    final email = await _settings.get('user_email') ?? '';
    if (!mounted) return;
    setState(() {
      _name.text = name;
      _email.text = email;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _settings.set('user_name', _name.text.trim());
    await _settings.set('user_email', _email.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('اتحفظ ✓', 'Saved ✓'))));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('تسجيل الخروج', 'Log out')),
        content: Text(tr(
            'هيتم مسح اسمك وإيميلك من الجهاز، وبياناتك (المواعيد/الفلوس/إلخ) هتفضل زي ما هي. تكمل؟',
            'Your name & email will be cleared from this device. Your data (appointments/money/etc.) stays. Continue?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('تسجيل الخروج', 'Log out'))),
        ],
      ),
    );
    if (ok != true) return;
    await _settings.set('user_name', '');
    await _settings.set('user_email', '');
    await _settings.set('onboarded', '0');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) =>
              const OnboardingGate(child: LockGate(child: Shell()))),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = _name.text.trim();
    return Scaffold(
      appBar: AppBar(title: Text(tr('حسابي', 'My account'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primary,
                    child: Text(name.isNotEmpty ? name.characters.first : '★',
                        style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: tr('الاسم', 'Name'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: tr('الإيميل (اختياري)', 'Email (optional)'),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(tr('حفظ', 'Save')),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: scheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: scheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              tr('حسابك حاليًا محلي على جهازك — كل بياناتك متخزّنة عندك بدون إنترنت. تسجيل الدخول بالإيميل والتأكيد عبر رسالة قيد الإعداد.',
                                  'Your account is currently local on this device — all data is stored offline. Email sign-in & verification are coming soon.'),
                              style: const TextStyle(fontSize: 12.5, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout, color: scheme.error),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  label: Text(tr('تسجيل الخروج', 'Log out')),
                ),
              ],
            ),
    );
  }
}
