import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/l10n.dart';

/// منتقي تاريخ بطريقة العجلة (زي طارة) — بديل موحّد لـ showDatePicker.
Future<DateTime?> pickWheelDate(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
}) async {
  var d = initial;
  if (d.isBefore(first)) d = first;
  if (d.isAfter(last)) d = last;
  var temp = d;
  final scheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: 320,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(tr('إلغاء', 'Cancel'))),
                Text(tr('اختار التاريخ', 'Pick date'),
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700)),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, temp),
                    child: Text(tr('تم', 'Done'))),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                  primaryColor: scheme.primary,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        color: scheme.onSurface),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: temp,
                  minimumDate: first,
                  maximumDate: last,
                  onDateTimeChanged: (v) => temp = v,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
