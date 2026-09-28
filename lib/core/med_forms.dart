import 'package:flutter/material.dart';

/// أشكال الدوا ووحداته — **مكان واحد** بيخدم «الأدوية» و«صيدلية البيت».
/// (القاعدة ٧: مفيش قوايم مكتوبة جوّه الشاشات.) كانوا فى `med_form.dart`
/// وحدهم؛ اتنقلوا هنا لمّا الصيدلية احتاجت نفس القايمة.
const List<String> kMedForms = [
  'أقراص',
  'كبسولات',
  'شراب',
  'فوار',
  'كريم',
  'مرهم',
  'حقن',
  'قطرة',
  'بخاخ',
  'لبوس',
  'أخرى',
];

const List<String> kMedUnits = [
  'علبة',
  'شريط',
  'قرص',
  'عبوة',
  'قطعة',
  'سرنجة',
  'زجاجة',
  'أنبوبة',
  'كيس',
  'أخرى',
];

/// أيقونة مميّزة لكل شكل — عشان الكارت يتقرا من نظرة من غير ما تقرا الاسم.
/// الشكل المش معروف بياخد أيقونة الدوا العامة.
IconData medFormIcon(String form) => switch (form) {
      'أقراص' || 'كبسولات' => Icons.medication,
      'شراب' || 'فوار' => Icons.local_drink_outlined,
      'كريم' || 'مرهم' => Icons.sanitizer_outlined,
      'حقن' => Icons.vaccines_outlined,
      'قطرة' => Icons.water_drop_outlined,
      'بخاخ' => Icons.air,
      'لبوس' => Icons.spa_outlined,
      _ => Icons.medication_outlined,
    };

/// أماكن التخزين المقترحة — نصّ حرّ برضه، دى مجرد اقتراحات بضغطة.
const List<String> kStoragePlaces = [
  'دولاب الأدوية',
  'دولاب المطبخ',
  'التلاجة',
  'الأوضة',
  'شنطة السفر',
  'العربية',
];
