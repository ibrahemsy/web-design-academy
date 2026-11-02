# إعداد Supabase لأكاديمية تصميم الويب

هذا الدليل يشرح تجهيز قاعدة البيانات والتخزين وربط تطبيق Flutter. لا تضع مفتاح `service_role` أو أي Secret key داخل التطبيق أو GitHub.

## 1. إنشاء مشروع Supabase

1. أنشئ مشروعاً من https://supabase.com/dashboard
2. انسخ Project URL ومفتاح Publishable من إعدادات API.
3. فعّل Email provider من Authentication → Providers.
4. اضبط Site URL وRedirect URLs لتشمل رابط النشر المحلي/الإنتاج الذي ستستخدمه.

## 2. تطبيق ملفات قاعدة البيانات

نفّذ ملفات `supabase/migrations/` بالترتيب الرقمي من `0001` إلى `0029` في SQL Editor، مرة واحدة لكل ملف:

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
12. `0012_teacher_course_roster_and_progress.sql` — عرض طلاب الدورة وتقدمهم للمدرّس/المدير.
13. `0013_restrict_preview_to_published_courses.sql` — منع معاينة دروس الدورات غير المنشورة.
14. `0014_restrict_archived_course_video_access.sql` — إيقاف وصول الطلاب لفيديوهات الدورات المؤرشفة.
15. `0015_serialize_admin_role_changes.sql` — منع تعارض طلبات تغيير أدوار المديرين بالتزامن.
16. `0016_minimize_teacher_report_payloads.sql` — تقليل البيانات الشخصية التي تظهر في تقارير المدرّسين.
17. `0017_recheck_admin_after_role_lock.sql` — إعادة التحقق من صلاحية المدير بعد قفل تغييرات الأدوار المتزامنة.
18. `0018_student_quiz_history_rpc.sql` — سجل نتائج الطالب حتى بعد أرشفة الدورة.
19. `0019_quiz_attempt_limits_and_passing_scores.sql` — درجة النجاح وحدود المحاولات المفروضة من قاعدة البيانات.
20. `0020_snapshot_quiz_passing_threshold.sql` — حفظ درجة النجاح وقت تسليم المحاولة حتى لا تتغير النتائج التاريخية.
21. `0021_quiz_attempt_history_indexes.sql` — تسريع التحقق من حد المحاولات وسجل الطالب.
22. `0022_course_certificates_and_verification.sql` — سجل الشهادات الخاص، إصدار الشهادة بعد إكمال الدروس واجتياز الاختبارات، والتحقق العام من الرمز.
23. `0023_certificate_snapshots_and_private_access_policy.sql` — حفظ اسم الطالب وعنوان الدورة وقت الإصدار ومنع أي وصول مباشر إلى جدول الشهادات.
24. `0024_teacher_course_certificate_report.sql` — تقرير الشهادات للمدرّس ومالك الدورة/المدير، مع منع الوصول إلى بيانات الدورات الأخرى.
25. `0025_increase_certificate_code_entropy.sql` — زيادة العشوائية لرموز الشهادات الجديدة إلى 122 بت من العشوائية الفعلية (UUIDv4) مع الحفاظ على صلاحية الرموز القديمة.
26. `0026_revoke_direct_private_certificate_report_access.sql` — منع تنفيذ دالة تقرير الشهادات الداخلية مباشرة، وإجبار الوصول على المرور عبر RPC العامة المحمية.
27. `0027_restrict_direct_private_certificate_verification.sql` — حصر التحقق من الشهادة في RPC العامة ذات `SECURITY DEFINER` ومنع استدعاء دالة التحقق الداخلية مباشرة.
28. `0028_harden_public_certificate_report_wrapper.sql` — جعل RPC تقرير الشهادات العامة غلافاً آمناً بصلاحيات المالك مع إبقاء التحقق من ملكية الدورة داخل الدالة الخاصة.
29. `0029_minimize_public_data_api_grants.sql` — إزالة صلاحيات الكتابة غير اللازمة ومنع TRUNCATE المباشر، وتقييد صلاحيات المستخدمين، وإيقاف منح صلاحيات افتراضية تلقائية للكائنات الجديدة.

إذا كانت هذه التغييرات مطبقة بالفعل على مشروع الأكاديمية المتصل، فلا تعِد تشغيلها عليه.

## 3. اختبار أمان قاعدة البيانات

بعد تطبيق جميع ملفات الترحيل، افتح SQL Editor وشغّل الملف `supabase/tests/security_smoke_test.sql`. هذا اختبار قراءة فقط يتحقق من خصوصية bucket الفيديو وسياساته، وسياسات الملف الشخصي والدورات وتقدم الطالب، وصلاحيات Data API المحدودة، وإغلاق الصلاحيات الافتراضية المستقبلية، ووجود حارس تغيير الأدوار، وتفعيل RLS على جدول الشهادات، ومنع القراءة المباشرة، وصلاحيات RPC للأدوار، واستخدام مولّد رموز الشهادات ذي 122 بت من العشوائية الفعلية (UUIDv4). يجب أن ينتهي دون أخطاء ويعرض رسالة `PASS`. لا يستبدل ذلك اختبارات قبول فعلية بحسابات طالب ومدرّس ومدير.

## 4. إنشاء حساب المدير الأول

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

## 5. تخزين الفيديو

- اسم bucket: `course-videos`.
- النوع: خاص (Private).
- الحد الأقصى المهيأ: 500 MB.
- الصيغ: MP4 وWebM وMOV.
- مسار الملف: `<course_uuid>/<filename>`.

سياسات التخزين تقصر القراءة على المدرّس/المدير والطلاب المسجلين، مع استثناء معاينات الدروس المنشورة. يستخدم التطبيق Signed URLs مؤقتة.

## 6. تشغيل Flutter

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

## 7. تقارير المدرّس والمدير

تعرض لوحة المتابعة مؤشرات كل دورة: عدد المسجلين، متوسط إنجاز الدروس، الشهادات الصادرة والمتبقية، وعدد الاختبارات والمحاولات والناجحين ومتوسط الدرجات. المدرّس مقيد بدوراته عبر `teacher_id`، وتتحقق دوال التقارير من ملكية الدورة أو صلاحية المدير. يمكن تنزيل تقارير CSV لقائمة الطلاب والتقدم، ونتائج الاختبارات، وسجل الشهادات. لا تحتاج هذه اللوحة إلى migration إضافية؛ فهي تستخدم دوال RPC المطبقة في الترحيلات السابقة.

## 8. التحقق الأمني والاختبارات

بعد تغييرات SQL شغّل Security وPerformance Advisors من Supabase. يجب مراجعة أي تحذيرات قبل الإطلاق. دوال الاختبارات والشهادات الآمنة:
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


بعد تغييرات SQL شغّل Supabase Security وPerformance Advisors من Supabase. يجب مراجعة أي تحذيرات قبل الإطلاق. قد يظهر تحذير `anon_security_definer_function_executable` و`authenticated_security_definer_function_executable` للدالتين `public.verify_course_certificate(text)` و`public.get_course_certificate_report(uuid)`؛ هذا استثناء مقصود لأن الأولى تحقق عام من الشهادة، والثانية RPC مخصصة للمستخدمين المسجلين. الدالة الثانية تتحقق داخلياً من هوية المستخدم وملكية الدورة أو صلاحية المدير، ولا تمنح `anon` حق التنفيذ. راجع تعريف الدالة: فهي لا تعيد إلا صلاحية الشهادة والاسم وعنوان الدورة وتاريخ الإصدار، بينما دالة التنفيذ الداخلية في `private` غير قابلة للاستدعاء المباشر من أدوار العميل.
