# نشر نسخة الويب — زى تطبيق طارة

التطبيق دلوقتي بيتبني ويب ويشتغل في المتصفح (اتّجرب محليًا: قاعدة البيانات
بتفتح عن طريق IndexedDB، من غير أخطاء). الباقي خطوات في المتصفح لازم تعملها
إنت لأنها محتاجة حسابك على GitHub و Firebase.

## اللى جاهز في الكود (اتعمل)
- `flutter build web` بيعدّي ويشتغل (sqflite على الويب عبر IndexedDB + sqlite3.wasm).
- `web/index.html` + `manifest.json` بالعربي RTL واسم «مساعدي».
- `firebase.json` — إعداد Hosting (no-cache عشان كل نشر يظهر فورًا).
- `.github/workflows/deploy-web.yml` — GitHub Action ينشر أوتوماتيك مع كل push على `master`.
- `.firebaserc` — فيه placeholder لاسم مشروع Firebase (لازم تغيّره — خطوة ٢).

## الخطوات اللى عليك (مرة واحدة)

### ١) اعمل ريبو على GitHub
- افتح github.com ← New repository ← اسمه مثلًا `my-assistant` ← Private أو Public (زى ما تحب).
- **مش تضيف** README أو .gitignore (الريبو عندنا جاهز).
- انسخ رابط الريبو (SSH أو HTTPS)، وابعتهولي — وأنا أعمل:
  `git remote add origin <الرابط>` ثم `git push -u origin master`.
  (أو تعملها إنت لو أسهل.)

### ٢) اعمل مشروع Firebase + فعّل Hosting
- افتح console.firebase.google.com ← Add project ← اسمه مثلًا `my-assistant-web`.
- من القايمة: **Build ← Hosting ← Get started** (كفاية أول خطوة).
- خُد **Project ID** (تحت اسم المشروع) وحطّه بدل `REPLACE_WITH_YOUR_FIREBASE_PROJECT_ID`
  في ملف `.firebaserc` — أو ابعتهولى وأنا أحطّه.
- اللينك بتاع التطبيق هيبقى: `https://<PROJECT_ID>.web.app`

### ٣) مفتاح حساب الخدمة (عشان الـ Action ينشر لوحده)
- في Firebase Console ← ⚙ Project settings ← **Service accounts** ←
  **Generate new private key** ← هينزّل ملف JSON.
- في GitHub ← الريبو ← Settings ← Secrets and variables ← Actions ←
  **New repository secret**:
  - الاسم: `FIREBASE_SERVICE_ACCOUNT`
  - القيمة: الصق محتوى ملف الـ JSON كله.

### ٤) خلاص
- أول ما نعمل push (أو تعدّل أى حاجة في `lib/` وتـpush)، الـ Action هيبني
  وينشر لوحده، واللينك `https://<PROJECT_ID>.web.app` يشتغل من أى متصفح/موبايل.

## ملاحظات
- نسخة الويب **للعرض والتجربة**: مفيش إشعارات/ودجت/كاميرا OCR (دول مزايا موبايل).
  كل الباقى (المواعيد، الأدوية، المحفظة، المستندات، العادات، التقارير...) شغّال.
- البيانات على الويب بتتخزن في المتصفح (IndexedDB) — مش بتتزامن مع الموبايل.
- لو عايز اللينك يبقى على دومين خاص بيك بدل `.web.app` نظبطه بعدين في Hosting.
