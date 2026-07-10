# R8 full mode بيشيل الـ constructor الفاضي اللي Room بينشئ بيه قواعد البيانات
# المولدة عبر reflection — من غير القواعد دي التطبيق بيقع عند الإقلاع بـ
# NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init> []
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }

# حزمة ML Kit بتشاور على موديلات لغات مش مضمنة عندنا (بنستخدم اللاتيني بس
# للأرقام والتواريخ) — R8 بيعتبرها كلاسات ناقصة فلازم نسكّته عنها.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
