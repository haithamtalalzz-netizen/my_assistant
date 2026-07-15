import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ar.dart';
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
import 'tasks/tasks_screen.dart';
import 'money/subscriptions_screen.dart';
import 'money/wishlist_screen.dart';
import 'growth/goals_screen.dart';
import 'growth/courses_screen.dart';
import 'growth/reading_screen.dart';
import 'growth/watchlist_screen.dart';
import 'car/car_screen.dart';
import 'renewals/renewals_screen.dart';
import 'travel/travel_screen.dart';
import 'pets/pets_screen.dart';
import 'health/vaccinations_screen.dart';
import 'health/lab_results_screen.dart';
import 'home/home_inventory_screen.dart';
import 'home/plants_screen.dart';

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
  // فلتر النوع: null = الكل.
  String? _filter;

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
      // الفلتر بيتلغى لو نوعه مابقاش موجود فى النتائج الجديدة.
      if (_filter != null && !hits.any((h) => h.kind == _filter)) {
        _filter = null;
      }
      _searching = false;
    });
  }

  /// اسم النوع للعرض فى شرائح الفلتر.
  String _kindLabel(String kind) => switch (kind) {
        'appointment' => tr('مواعيد', 'Appointments'),
        'expense' => tr('مصاريف', 'Expenses'),
        'income' => tr('دخل', 'Income'),
        'medication' => tr('أدوية', 'Meds'),
        'document' => tr('مستندات', 'Docs'),
        'medical' => tr('سجل طبى', 'Medical'),
        'pharmacy' => tr('صيدلية', 'Pharmacy'),
        'warranty' => tr('ضمانات', 'Warranties'),
        'debt' => tr('ديون', 'Debts'),
        'social' => tr('واجبات', 'Social'),
        'clothing' => tr('ملابس', 'Clothes'),
        'savings' => tr('ادخار', 'Savings'),
        'habit' => tr('عادات', 'Habits'),
        'meal' => tr('وجبات', 'Meals'),
        'home_maint' => tr('صيانة', 'Maintenance'),
        'task' => tr('مهام', 'Tasks'),
        'subscription' => tr('اشتراكات', 'Subscriptions'),
        'goal' => tr('أهداف', 'Goals'),
        'car' => tr('سيارات', 'Cars'),
        'renewal' => tr('تجديدات', 'Renewals'),
        'trip' => tr('سفر', 'Trips'),
        'course' => tr('دورات', 'Courses'),
        'pet' => tr('حيوانات', 'Pets'),
        'vaccination' => tr('تطعيمات', 'Vaccines'),
        'lab' => tr('تحاليل', 'Labs'),
        'wish' => tr('أمنيات', 'Wishlist'),
        'watch' => tr('مشاهدة', 'Watchlist'),
        'book' => tr('كتب', 'Books'),
        'inventory' => tr('جرد البيت', 'Inventory'),
        'plant' => tr('نباتات', 'Plants'),
        _ => kind,
      };

  /// شرائح فلترة بالنوع — بتظهر بس لما يبقى فيه أكتر من نوع فى النتائج.
  Widget _filterChips() {
    final kinds = <String>[];
    for (final h in _results) {
      if (!kinds.contains(h.kind)) kinds.add(h.kind);
    }
    if (kinds.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ChoiceChip(
              label: Text(tr('الكل (${arNum(_results.length)})',
                  'All (${arNum(_results.length)})')),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
          ),
          for (final k in kinds)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                avatar: Icon(_iconFor(k), size: 16),
                label: Text(
                    '${_kindLabel(k)} (${arNum(_results.where((h) => h.kind == k).length)})'),
                selected: _filter == k,
                onSelected: (_) => setState(() => _filter = k),
              ),
            ),
        ],
      ),
    );
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
        'task' => Icons.checklist_outlined,
        'subscription' => Icons.subscriptions_outlined,
        'goal' => Icons.flag_outlined,
        'car' => Icons.directions_car_outlined,
        'renewal' => Icons.badge_outlined,
        'trip' => Icons.flight_takeoff_outlined,
        'course' => Icons.school_outlined,
        'pet' => Icons.pets_outlined,
        'vaccination' => Icons.vaccines_outlined,
        'lab' => Icons.biotech_outlined,
        'wish' => Icons.card_giftcard_outlined,
        'watch' => Icons.movie_outlined,
        'book' => Icons.menu_book_outlined,
        'inventory' => Icons.inventory_2_outlined,
        'plant' => Icons.local_florist_outlined,
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
        'task' => const TasksScreen(),
        'subscription' => const SubscriptionsScreen(),
        'goal' => const GoalsScreen(),
        'car' => const CarScreen(),
        'renewal' => const RenewalsScreen(),
        'trip' => const TravelScreen(),
        'course' => const CoursesScreen(),
        'pet' => const PetsScreen(),
        'vaccination' => const VaccinationsScreen(),
        'lab' => const LabResultsScreen(),
        'wish' => const WishlistScreen(),
        'watch' => const WatchlistScreen(),
        'book' => const ReadingScreen(),
        'inventory' => const HomeInventoryScreen(),
        'plant' => const PlantsScreen(),
        _ => null, // meal مفيش ليها شاشة مستقلة
      };

  Widget _resultsList(ColorScheme scheme) {
    final shown = _filter == null
        ? _results
        : [for (final h in _results) if (h.kind == _filter) h];
    return ListView.builder(
      itemCount: shown.length,
      itemBuilder: (context, i) {
        final hit = shown[i];
        return ListTile(
          leading: Icon(_iconFor(hit.kind), color: scheme.primary),
          title: Text(hit.title),
          subtitle: Text(hit.subtitle),
          onTap: () => _open(hit),
        );
      },
    );
  }

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
                  : Column(
                      children: [
                        _filterChips(),
                        Expanded(child: _resultsList(scheme)),
                      ],
                    ),
    );
  }
}
