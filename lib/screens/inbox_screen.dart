import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../widgets/search_action.dart';
import '../data/inbox_repo.dart';
import '../data/meals_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'schedule/appointment_form.dart';

/// صندوق الوارد: أفكار سريعة غير مصنفة — تتسجل في ثانية وتتصنف بعدين.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _repo = InboxRepo();
  final _input = TextEditingController();
  bool _loading = true;
  List<InboxNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final notes = await _repo.all();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _add() async {
    if (_input.text.trim().isEmpty) return;
    await _repo.add(_input.text);
    _input.clear();
    await _load();
  }

  Future<void> _toAppointment(InboxNote note) async {
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => AppointmentForm(
                appointment: Appointment(
              title: note.text,
              category: 'شخصي',
              when: DateTime.now().add(const Duration(days: 1)),
            ))));
    if (saved == true) {
      await _repo.delete(note.id!);
      if (mounted) await _load();
    }
  }

  Future<void> _toShopping(InboxNote note) async {
    await MealsRepo().addShoppingItem(note.text);
    await _repo.delete(note.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('اتنقلت لقائمة التسوق ✓', 'Moved to shopping list ✓'))));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('صندوق الوارد', 'Inbox')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          decoration: InputDecoration(
                              labelText:
                                  tr('ارمي أي فكرة هنا...', 'Drop any idea here...')),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                          onPressed: _add, icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                Expanded(
                  child: _notes.isEmpty
                      ? EmptyHint(
                          icon: Icons.inbox_outlined,
                          text:
                              tr('فاضي — أي فكرة تيجي في دماغك ارميها هنا\nوصنفها لما تفضى',
                                  'Empty — drop any idea here\nand sort it later'))
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            for (final note in _notes)
                              Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 3),
                                child: ListTile(
                                  dense: true,
                                  title: Text(note.text),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      switch (v) {
                                        case 'appt':
                                          await _toAppointment(note);
                                        case 'shop':
                                          await _toShopping(note);
                                        case 'delete':
                                          await _repo.delete(note.id!);
                                          if (mounted) await _load();
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'appt',
                                          child: Text(tr('حوّلها لموعد',
                                              'Make appointment'))),
                                      PopupMenuItem(
                                          value: 'shop',
                                          child:
                                              Text(tr('حطها في التسوق',
                                                  'Add to shopping'))),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text(tr('خلصت — امسحها',
                                              'Done — delete'))),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
