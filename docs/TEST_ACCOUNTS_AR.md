# حسابات الاختبار المحلية

هذا الإجراء ينشئ **مستخدمين حقيقيين في Supabase Auth** لأغراض الاختبار، وليس سجلات وهمية داخل جدول profiles فقط. الحسابات تستخدم نطاق `example.com` المحجوز للأمثلة؛ لذلك يتم تأكيد البريد داخل Auth دون إرسال رسالة بريد.

## الحسابات التي ينشئها السكربت

| البريد | الدور |
|---|---|
| academy.admin@example.com | admin |
| academy.teacher@example.com | teacher |
| academy.student@example.com | student |

كلمات المرور تُولّد عشوائياً لكل حساب وتُحفظ محلياً في `test-accounts.generated.json`. لا يطبع السكربت كلمات المرور، ولا يغيّر كلمة مرور أو دور حساب موجود. الحساب الموجود مسبقاً يتم تجاوزه.

## تشغيل آمن

1. استخدم مشروع Supabase مخصصاً للاختبار، وليس مشروع الإنتاج.
2. افتح Terminal في مجلد المستودع وثبّت Node.js 20 أو أحدث.
3. عيّن المتغيرات في جلسة الطرفية فقط، ولا تضع المفتاح في ملف داخل المستودع:

```bash
export SUPABASE_URL="https://dgeohwxzleznygmfjfdq.supabase.co"
read -s -p "Supabase service role key: " SUPABASE_SERVICE_ROLE_KEY
export SUPABASE_SERVICE_ROLE_KEY
echo
export ALLOW_TEST_ACCOUNTS_ON_PROJECT="dgeohwxzleznygmfjfdq"
node scripts/create_test_accounts.mjs
unset SUPABASE_SERVICE_ROLE_KEY
```

4. افتح `test-accounts.generated.json` محلياً للحصول على كلمات المرور. الملف مستثنى من Git.
5. بعد الاختبار، احذف الحسابات التجريبية من Authentication → Users إذا لم تعد بحاجة إليها.

## ضوابط

- المفتاح المطلوب هو Service Role/Secret key، ويظل محلياً على جهازك فقط. لا ترسله إلى ChatGPT ولا تضفه إلى GitHub أو Flutter.
- السكربت مقيد بمعرّف المشروع الحالي `dgeohwxzleznygmfjfdq` ويتوقف إذا لم يتطابق عنوان المشروع ومتغير الموافقة.
- لا يشغّل السكربت أي SQL، ولا ينشئ دوراً من بيانات المستخدم القابلة للتعديل؛ يحدّث عمود `profiles.role` عبر امتياز الخادم بعد إنشاء Auth user.
- إذا فشل إنشاء أي حساب أو ضبط دوره، يحاول السكربت حذف الحسابات التي أنشأها في التشغيل الحالي فقط.
- لا تستخدم حساب المدير التجريبي على مشروع إنتاجي أو مع بيانات حقيقية.
