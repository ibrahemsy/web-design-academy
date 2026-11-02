# إعداد Supabase لأكاديمية تصميم الويب

هذا الدليل يشرح تجهيز قاعدة البيانات والتخزين وربط تطبيق Flutter. لا تضع مفتاح `service_role` أو أي Secret key داخل التطبيق أو GitHub.

## 1. إنشاء مشروع Supabase

1. أنشئ مشروعاً من https://supabase.com/dashboard
2. انسخ Project URL ومفتاح Publishable من إعدادات API.
3. فعّل Email provider من Authentication → Providers.
4. اضبط Site URL وRedirect URLs لتشمل رابط النشر المحلي/الإنتاج الذي ستستخدمه.

## 2. تطبيق ملفات قاعدة البيانات

نفّذ ملفات `supabase/migrations/` بالترتيب الرقمي من `0001` إلى `0010` في SQL Editor، مرة واحدة لكل ملف:

1. `0001_initial_schema.sql` — الجداول والأدوار والعلاقات الأساسية.
2. `0002_security_hardening.sql` — دوال الصلاحيات وحماية الأدوار.
3. `0003_fix_lesson_enrollment_policy.sql` — تصحيح رؤية الدروس للمسجلين.
4. `0004_add_quiz_foreign_key_indexes.sql` — فهارس علاقات الاختبارات.
5. `0005_secure_quiz_delivery_and_grading.sql` — تسليم الاختبارات والتصحيح داخل الخادم.
6. `0006_quiz_question_validation_and_visibility.sql` — التحقق من خيارات الأسئلة وسياسات الرؤية.
7. `0007_teacher_quiz_results_and_history.sql` — نتائج المدرّس.
8. `0008_optimize_rls_and_admin_video_permissions.sql` — تحسين سياسات RLS ودعم إدارة المدير للفيديو.
9. `0009_consolidate_select_policies.sql` — دمج سياسات القراءة لتقليل التكرار.
10. `0010_allow_preview_video_playback.sql` — مشاهدة فيديوهات المعاينة المنشورة مع بقاء bucket خاصاً.
11. `0011_admin_user_role_management.sql` — إدارة أدوار الحسابات من لوحة المدير مع حماية آخر مدير.

إذا كانت هذه التغييرات مطبقة بالفعل على مشروع الأكاديمية المتصل، فلا تعِد تشغيلها عليه.

## 3. إنشاء حساب المدير الأول

1. افتح الأكاديمية وأنشئ حساباً عادياً بالبريد الإلكتروني.
2. افتح Supabase → Authentication → Users وانسخ UUID للحساب.
3. افتح SQL Editor ونفّذ بعد استبدال UUID:

```sql
update public.profiles
set role = 'admin'
where id = 'ضع-UUID-الحساب-هنا';
```

لمنح حساب آخر دور المدرّس:

```sql
update public.profiles
set role = 'teacher'
where id = 'ضع-UUID-حساب-المدرّس-هنا';
```

الحسابات الجديدة تبدأ بدور `student`. لا توجد واجهة تسمح للمستخدم بتغيير دوره. لا تمنح دور المدير إلا للحسابات الموثوقة.

## 4. تخزين الفيديو

- اسم bucket: `course-videos`.
- النوع: خاص (Private).
- الحد الأقصى المهيأ: 500 MB.
- الصيغ: MP4 وWebM وMOV.
- مسار الملف: `<course_uuid>/<filename>`.

سياسات التخزين تقصر القراءة على المدرّس/المدير والطلاب المسجلين، مع استثناء معاينات الدروس المنشورة. يستخدم التطبيق Signed URLs مؤقتة.

## 5. تشغيل Flutter

```bash
flutter pub get
flutter run -d chrome
```

لبناء نسخة GitHub Pages:

```bash
flutter build web --release --base-href /web-design-academy/
```

يمكن تجاوز الإعدادات الافتراضية باستخدام:

```bash
flutter build web --release \
  --base-href /web-design-academy/ \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

مفتاح Publishable مخصص للاستخدام في تطبيق العميل؛ الحماية الفعلية تعتمد على RLS. لا تستخدم `service_role` أو Secret key في Flutter.

## 6. التحقق الأمني والاختبارات

بعد تغييرات SQL شغّل Security وPerformance Advisors من Supabase. يجب مراجعة أي تحذيرات قبل الإطلاق. دوال الاختبارات الآمنة:
- `get_quiz_for_student`: تعيد نص السؤال والخيارات فقط.
- `submit_quiz_attempt`: تتحقق من الإجابات وتحسب الدرجة داخل قاعدة البيانات.
- `get_quiz_results_for_teacher`: لا تعرض النتائج إلا لمالك الدورة أو المدير.

قبل استقبال الطلاب، اختبر عملياً:
1. حساب طالب لا يستطيع قراءة مسودة أو دورة غير مسجل فيها.
2. الطالب لا يستطيع قراءة `correct_option` أو إدخال/تعديل درجات المحاولات مباشرة.
3. المدرّس لا يستطيع عرض نتائج دورة مدرس آخر.
4. المدير يستطيع إدارة الدورات والاختبارات والفيديوهات.
5. معاينة منشورة يمكن مشاهدتها دون تسجيل الطالب في الدورة، ولا يُحفظ تقدمها.
6. الدرس المسجل فيه يحفظ التقدم ويستأنف المشاهدة.

لم يُنفذ بعد اختبار قبول شامل بحسابات طالب ومدرّس ومدير حقيقية. لا تشارك كلمات المرور أو المفاتيح السرية عند طلب المساعدة.
