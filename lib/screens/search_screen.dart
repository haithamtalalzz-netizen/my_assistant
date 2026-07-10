import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../data/search_repo.dart';
import 'baladna/debts_screen.dart';
import 'baladna/savings_screen.dart';
import 'baladna/social_screen.dart';
import 'docs/docs_screen.dart';
import 'habits/habits_screen.dart';
import 'home/pharmacy_screen.dart';
import 'home/warranty_screen.dart';
import 'baladna/home_maintenance_screen.dart';
import 'medical/medical_screen.dart';
import 'money/money_screen.dart';
import 'schedule/schedule_screen.dart';
import 'wardrobe/wardrobe_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repo = SearchRepo();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  List<SearchHit> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(q));
  }

  Future<void> _run(String q) async {
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final hits = await _repo.search(q);
    if (!mounted) return;
    setState(() {
      _results = hits;
      _searching = false;
    });
  }

  IconData _iconFor(String kind) => switch (kind) {
        'appointment' => Icons.event,
        'expense' => Icons.account_balance_wallet_outlined,
        'income' => Icons.south_west,
        'medication' => Icons.medication_outlined,
        'document' => Icons.folder_outlined,
        'medical' => Icons.medical_information_outlined,
        'pharmacy' => Icons.medication,
        'warranty' => Icons.verified_outlined,
        'debt' => Icons.handshake_outlined,
        'social' => Icons.volunteer_activism_outlined,
        'clothing' => Icons.checkroom_outlined,
        'savings' => Icons.savings_outlined,
        'habit' => Icons.task_alt,
        'meal' => Icons.restaurant_outlined,
        'home_maint' => Icons.home_repair_service_outlined,
        _ => Icons.search,
      };

  Widget? _screenFor(String kind) => switch (kind) {
        'appointment' || 'medication' => const ScheduleScreen(),
        'expense' || 'income' => const MoneyScreen(),
        'document' => const DocsScreen(),
        'medical' => const MedicalScreen(),
        'pharmacy' => const PharmacyScreen(),
        'warranty' => const WarrantyScreen(),
        'debt' => const DebtsScreen(),
        'social' => const SocialScreen(),
        'clothing' => const WardrobeScreen(),
        'savings' => const SavingsScreen(),
        'habit' => const HabitsScreen(),
        'home_maint' => const HomeMaintenanceScreen(),
        _ => null, // meal مفيش ليها شاشة مستقلة
      };

  void _open(SearchHit hit) {
    final screen = _screenFor(hit.kind);
    if (screen != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: tr('دوّر على أي حاجة...', 'Search anything...'),
          ),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                _run('');
              },
            ),
        ],
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : _ctrl.text.trim().length < 2
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                        tr('اكتب كلمتين على الأقل — بندوّر في كل حاجة سجّلتها',
                            'Type at least 2 letters — searches everything you logged'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.outline)),
                  ))
              : _results.isEmpty
                  ? Center(
                      child: Text(tr('مفيش نتائج', 'No results'),
                          style: TextStyle(color: scheme.outline)))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final hit = _results[i];
                        return ListTile(
                          leading: Icon(_iconFor(hit.kind),
                              color: scheme.primary),
                          title: Text(hit.title),
                          subtitle: Text(hit.subtitle),
                          onTap: () => _open(hit),
                        );
                      },
                    ),
    );
  }
}
