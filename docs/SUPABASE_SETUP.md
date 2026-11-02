# ربط Supabase بأكاديمية تصميم الويب

هذا الدليل يجهّز قاعدة البيانات والتخزين. لا تضع مفاتيح Supabase السرية في GitHub أو داخل تطبيق Flutter.

## 1) إنشاء مشروع Supabase
1. أنشئ مشروعاً جديداً من https://supabase.com/dashboard
2. احتفظ بعنوان Project URL ومفتاح publishable/anon للاستخدام في تطبيق العميل.
3. لا تستخدم `service_role` أو أي Secret key داخل Flutter أو المستودع.

## 2) إنشاء قاعدة البيانات
1. افتح مشروع Supabase ثم SQL Editor.
2. افتح الملف `supabase/migrations/0001_initial_schema.sql` من هذا المستودع.
3. انسخ محتواه كاملاً إلى SQL Editor ثم نفّذه.
4. من Authentication فعّل طريقة Email، واضبط رابط إعادة التوجيه إلى رابط موقعك عند تفعيله.

ينشئ المخطط جداول المستخدمين والدورات والدروس والتسجيل والتقدم والاختبارات، ويفعّل Row Level Security.

## 3) ترقية حسابك الأول إلى مدير
1. أنشئ حساباً عادياً من نظام المصادقة بعد ربط التطبيق.
2. افتح Authentication → Users وانسخ UUID الخاص بحسابك.
3. نفّذ في SQL Editor (مع استبدال القيمة):

```sql
update public.profiles
set role = 'admin'
where id = 'ضع-UUID-الحساب-هنا';
```

بعدها يستطيع المدير منح دور المدرس من لوحة إدارة موثوقة. لا تمنح المستخدمين صلاحية تغيير دورهم بأنفسهم.

## 4) تخزين الفيديو
تنشئ الهجرة bucket خاصاً باسم `course-videos` بحد أقصى 500MB وبأنواع MP4 وWebM وMOV. ارفع ملفات الفيديو ضمن مسار:
`<course_uuid>/<filename>`

الوصول للملفات خاص؛ الطالب المسجل في الدورة ومدرس الدورة فقط يستطيعان قراءتها وفق السياسات. استخدم signed URLs لمشاهدة الفيديوهات، ولا تجعل bucket عاماً.

## 5) إعداد Flutter
بعد إنشاء المشروع، أضف الحزمة:

```bash
flutter pub add supabase_flutter
```

ثم هيّئ العميل في نقطة بدء التطبيق باستخدام القيم العامة من Supabase:

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

وشغّل البناء محلياً مع تمرير القيم:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

هذه القيم العامة لا تحل محل سياسات RLS. لا تضف Service Role key إلى التطبيق مطلقاً.

## ملاحظات قبل الإطلاق
- الواجهة الحالية ما زالت نموذج MVP؛ لم نربط بعد شاشة تسجيل الدخول أو واجهة إدارة الدورات فعلياً.
- لا تعرض جدول `quiz_questions` للطلاب لأنه يحتوي الإجابات الصحيحة؛ أضف لاحقاً RPC آمنة للتصحيح وإرجاع النتيجة فقط.
- اختبر سياسات RLS بحساب طالب ومدرس ومدير قبل نشر بيانات حقيقية.
- رفع الفيديوهات الكبيرة قد يحتاج رفعاً resumable ومراقبة حدود التخزين وخطة Supabase المناسبة.
