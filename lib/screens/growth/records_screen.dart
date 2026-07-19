import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/personal_records.dart';
import '../../widgets/common.dart';

/// «أرقامك القياسية» — أفضل ما حقّقه المستخدم عبر كل البنود (قراءة فقط).
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late Future<List<PersonalRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = computePersonalRecords();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('أرقامك القياسية', 'Your records'))),
      body: FutureBuilder<List<PersonalRecord>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final recs = snap.data ?? const <PersonalRecord>[];
          if (recs.isEmpty) {
            return EmptyHint(
              icon: Icons.emoji_events_outlined,
              text: tr(
                  'لسه مفيش أرقام قياسية — استخدم التطبيق كام يوم وهتبان هنا أفضل إنجازاتك.',
                  'No records yet — use the app for a few days and your bests will appear here.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, right: 4, left: 4),
                child: Text(
                  tr('أفضل ما حقّقته 🏆', 'Your all-time bests 🏆'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: scheme.primary),
                ),
              ),
              for (final r in recs) _RecordCard(record: r),
            ],
          );
        },
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final PersonalRecord record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(record.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(record.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: (record.sub != null && record.sub!.isNotEmpty)
            ? Text(record.sub!)
            : null,
        trailing: Text(
          record.value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: scheme.primary),
        ),
      ),
    );
  }
}
