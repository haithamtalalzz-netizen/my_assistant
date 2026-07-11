# نشر نسخة الويب — GitHub Pages

التطبيق **local-first** (كل البيانات على جهاز المستخدم عبر IndexedDB، مفيش سيرفر).
نسخة الويب مجرّد ملفات ثابتة، بتتنشر مجانًا على **GitHub Pages** — مفيش Firebase ولا أسرار.

## اللى جاهز في الكود (اتعمل)
- `flutter build web --release` بيعدّي ويشتغل (sqflite على الويب عبر IndexedDB + sqlite3.wasm).
- `web/index.html` + `manifest.json` بالعربي RTL واسم «مساعدي».
- `.github/workflows/deploy-pages.yml` — GitHub Action ينشر على Pages أوتوماتيك مع كل push
  على `master` (الـbase-href بيتحسب لوحده من اسم الريبو).

## الخطوات اللى عليك (مرة واحدة)

1. **اعمل GitHub repo** فاضي (Public) — مثلًا `my_assistant`. من غير README/‏.gitignore.
2. اربط المشروع وادفع الكود:
   ```bash
   git remote add origin https://github.com/<USERNAME>/<REPO>.git
   git push -u origin master
   ```
3. من الريبو على GitHub: **Settings → Pages → Source = "GitHub Actions"**.
4. خلاص. أول push بيشغّل الـworkflow: بيبني الويب وينشره على Pages.

اللينك بيطلع في **Settings → Pages** (شكله `https://<username>.github.io/<repo>/`)
وكمان في صفحة الـActions تحت الـdeploy.

## بعد كده (تلقائي)

أي `git push` على `master` بيبني وينشر أحدث نسخة أوتوماتيك — مفيش خطوات يدوية.

## ملاحظات

- **مفيش service worker** (`--pwa-strategy=none`) + المتصفح بيجيب أحدث نسخة → مفيش مشكلة كاش قديم.
- المستخدم يقدر يعمل **«إضافة للشاشة الرئيسية»** من المتصفح فتشتغل زي تطبيق (PWA) على أندرويد و iOS.
- **hash URL strategy** (الافتراضي) → مفيش مشاكل refresh على المسارات الفرعية في Pages.
- نسخة الويب **للعرض والتجربة**: مفيش إشعارات/ودجت/كاميرا OCR (دول مزايا موبايل). كل الباقي شغّال.
- البيانات على الويب بتتخزن في المتصفح (IndexedDB) — مش بتتزامن مع الموبايل.
- لو عايز دومين خاص بدل `github.io` نظبطه بعدين من Settings → Pages → Custom domain.
