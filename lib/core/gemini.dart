import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import '../data/settings_repo.dart';

/// عميل Gemini بالمستوى المجاني — مفتاح من aistudio.google.com من غير كارت.
/// من غير مفتاح كل النداءات بترجع null والتطبيق بيشتغل عادي بالقواعد المحلية.
class GeminiClient {
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static Future<bool> hasKey() async {
    final key = await SettingsRepo().get('gemini_key') ?? '';
    return key.isNotEmpty;
  }

  /// يرجع رد النص أو null لو مفيش مفتاح/فشل الاتصال.
  static Future<String?> ask({
    required String system,
    required String question,
  }) async {
    final key = (await SettingsRepo().get('gemini_key') ?? '').trim();
    if (key.isEmpty) return null;
    for (final model in _models) {
      try {
        final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': key,
              },
              body: jsonEncode({
                'system_instruction': {
                  'parts': [
                    {'text': system}
                  ]
                },
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': question}
                    ]
                  }
                ],
              }),
            )
            .timeout(const Duration(seconds: 45));
        if (response.statusCode == 404) continue; // موديل اتشال — جرب اللي بعده
        if (response.statusCode != 200) {
          dev.log('Gemini $model رجع ${response.statusCode}: ${response.body}');
          if (response.statusCode == 429) {
            return 'الحصة المجانية اتستهلكت مؤقتًا — جرب تاني بعد دقيقة.';
          }
          continue;
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = json['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) continue;
        final parts =
            ((candidates.first as Map)['content'] as Map)['parts'] as List?;
        if (parts == null || parts.isEmpty) continue;
        final text = (parts.first as Map)['text'] as String?;
        if (text != null && text.trim().isNotEmpty) return text.trim();
      } on Exception catch (e) {
        dev.log('فشل نداء Gemini ($model)', error: e);
      }
    }
    return 'معرفتش أوصل للخدمة — اتأكد من النت والمفتاح وجرب تاني.';
  }
}
