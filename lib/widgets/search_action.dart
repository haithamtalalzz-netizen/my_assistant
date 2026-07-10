import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../screens/search_screen.dart';

/// زر بحث موحّد لكل شاشات التطبيق — بيفتح البحث الشامل (بيدوّر في كل البيانات
/// بما فيها بيانات الصفحة الحالية). يتحط في `actions` بتاعة الـ AppBar.
Widget searchAction(BuildContext context) => IconButton(
      tooltip: tr('بحث', 'Search'),
      icon: const Icon(Icons.search),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
    );
