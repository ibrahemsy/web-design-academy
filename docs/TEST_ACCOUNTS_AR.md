<!-- Copyright (c) 2026 Ibrahim Zainab. All rights reserved. | GitHub: https://github.com/ibrahemsy -->

# إنشاء حسابات الاختبار

ينشئ هذا الإجراء مستخدمين حقيقيين في Supabase Auth لأغراض الاختبار. البريد على نطاق `example.com` المحجوز للأمثلة، ويؤكد السكربت البريد داخل Auth لأن النطاق غير مخصص لاستقبال البريد.

## الحسابات

| البريد | الدور المطلوب |
|---|---|
| academy.admin@example.com | admin |
| academy.teacher@example.com | teacher |
| academy.student@example.com | student |

تُولّد كلمات مرور عشوائية، وتُحفظ محلياً في `test-accounts.generated.json`. ويولّد السكربت ملف SQL منفصلاً `test-accounts-roles.generated.sql` لتعيين دور المدير والمدرّس من SQL Editor.

## التشغيل

1. يفضّل استخدام مشروع Supabase مخصص للاختبار. السكربت مقيد حالياً بمعرّف المشروع `dgeohwxzleznygmfjfdq` ولا يعمل على مشروع آخر.
2. افتح Terminal في مجلد المستودع، مع تثبيت Node.js 20 أو أحدث.
3. عيّن المتغيرات في جلسة الطرفية فقط:

```bash
export SUPABASE_URL="https://dgeohwxzleznygmfjfdq.supabase.co"
read -s -p "Supabase service role key: " SUPABASE_SERVICE_ROLE_KEY
export SUPABASE_SERVICE_ROLE_KEY
echo
export ALLOW_TEST_ACCOUNTS_ON_PROJECT="dgeohwxzleznygmfjfdq"
node scripts/create_test_accounts.mjs
unset SUPABASE_SERVICE_ROLE_KEY
```

4. افتح `test-accounts-roles.generated.sql`، راجع معرّفات الحسابات، ثم نفّذه في Supabase Dashboard → SQL Editor.
5. استخدم كلمات المرور الموجودة في `test-accounts.generated.json` لتسجيل الدخول. لا ترفع الملفين إلى GitHub أو أي خدمة مشاركة.

## لماذا تعيين الأدوار في SQL Editor؟

حارس قاعدة البيانات يمنع تحديث الأدوار عبر طلبات REST حتى لو استُخدم مفتاح الخدمة. يسمح فقط بعملية bootstrap الموثوقة من مالك المشروع عبر SQL Editor. لذلك ينشئ السكربت حسابات Auth ويترك تغيير الأدوار لملف SQL يراجعه مالك المشروع. لا يغيّر السكربت كلمة مرور أو دور أي حساب موجود، ويتراجع عن الحسابات الجديدة التي أنشأها إذا فشل أثناء العملية.

## التنظيف

بعد انتهاء الاختبار، احذف الحسابات التجريبية من Supabase → Authentication → Users، ثم احذف ملفي البيانات المحليين بأمان. لا تستخدم حساب المدير التجريبي في بيئة الإنتاج.
