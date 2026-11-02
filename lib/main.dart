import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://dgeohwxzleznygmfjfdq.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_8keAnBnVzcVWY7cDGDrlHQ_JWIyYOVO',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(const WebDesignAcademy());
}

final supabase = Supabase.instance.client;

const ink = Color(0xFF17243B);
const navy = Color(0xFF101B32);
const purple = Color(0xFF6C63FF);
const canvas = Color(0xFFF5F6FB);

class WebDesignAcademy extends StatelessWidget {
  const WebDesignAcademy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'أكاديمية تصميم الويب',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: purple, brightness: Brightness.light),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: ink, elevation: 0),
      ),
      home: const AuthGate(),
    );
  }
}

class Course {
  final String title, category, description, duration, level;
  final IconData icon;
  final Color color;
  final double progress;
  final String? id;
  final String status;
  const Course(this.title, this.category, this.description, this.duration, this.level,
      this.icon, this.color, this.progress, {this.id, this.status = 'published'});
}

const courses = [
  Course('أساسيات تصميم الويب', 'البداية الصحيحة', 'تعرّف إلى الويب، المتصفحات، وبنية صفحات المواقع.', '6 دروس', 'مبتدئ', Icons.language, Color(0xFF6C63FF), .72),
  Course('HTML من الصفر', 'تطوير الواجهات', 'أنشئ هيكل صفحاتك باستخدام عناصر HTML الدلالية.', '12 درساً', 'مبتدئ', Icons.code, Color(0xFFFF8A65), .35),
  Course('CSS والتصميم المرئي', 'التنسيق والإبداع', 'أتقن الألوان والخطوط والتخطيطات والتصميم المتجاوب.', '15 درساً', 'مبتدئ', Icons.palette_outlined, Color(0xFF18A999), .12),
  Course('JavaScript التفاعلية', 'برمجة الويب', 'أضف التفاعل والحركة والمنطق إلى صفحات الويب.', '18 درساً', 'متوسط', Icons.bolt, Color(0xFFF2B544), 0),
];


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = supabase.auth.currentUser;
        if (user == null) return const AuthScreen();
        return FutureBuilder(
          future: supabase.from('profiles').select('role').eq('id', user.id).maybeSingle(),
          builder: (context, profile) {
            if (profile.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final role = profile.data?['role'] as String? ?? 'student';
            return AcademyHome(isTeacher: role == 'teacher' || role == 'admin');
          },
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6 ||
        (_register && _name.text.trim().isEmpty)) {
      _show('أدخل البريد وكلمة مرور من 6 أحرف على الأقل، والاسم عند التسجيل.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_register) {
        await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim()},
        );
        _show('تم إرسال طلب التسجيل. تحقق من بريدك إذا كان تأكيد البريد مفعّلاً.');
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      _show(e.message);
    } catch (e) {
      _show('تعذر إكمال العملية. تحقق من اتصال الإنترنت وإعدادات المشروع.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.school_rounded, color: purple, size: 54),
                  const SizedBox(height: 14),
                  const Text('أكاديمية تصميم الويب',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 8),
                  Text(_register ? 'أنشئ حسابك وابدأ رحلة التعلم' : 'سجّل الدخول لمتابعة تعلمك',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
                  const SizedBox(height: 24),
                  if (_register) ...[
                    TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 12),
                  TextField(controller: _password, obscureText: _hidePassword,
                    decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hidePassword = !_hidePassword))),
                    onSubmitted: (_) { if (!_busy) _submit(); }),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_register ? 'إنشاء حساب' : 'تسجيل الدخول')),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _register = !_register),
                    child: Text(_register ? 'لديك حساب؟ سجّل الدخول' : 'ليس لديك حساب؟ أنشئ حساباً جديداً')),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}


class LessonPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String lessonId;
  const LessonPlayerScreen({super.key, required this.title, required this.videoUrl, required this.lessonId});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialize;
  bool _savingProgress = false;
  bool _completed = false;

  Future<void> _markCompleted() async {
    setState(() => _savingProgress = true);
    try {
      await supabase.from('lesson_progress').upsert({
        'lesson_id': widget.lessonId,
        'student_id': supabase.auth.currentUser!.id,
        'completed': true,
        'watched_seconds': _controller.value.position.inSeconds,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'lesson_id,student_id');
      if (mounted) setState(() => _completed = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ تقدمك في هذا الدرس.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التقدم: ' + error.toString())));
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialize = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: FutureBuilder<void>(
          future: _initialize,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return const Text('تعذر تشغيل الفيديو. جرّب رفع ملف MP4 أو WebM.');
            }
            return Column(mainAxisSize: MainAxisSize.min, children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              VideoProgressIndicator(_controller, allowScrubbing: true),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _savingProgress || _completed ? null : _markCompleted,
                icon: Icon(_completed ? Icons.check_circle : Icons.task_alt),
                label: Text(_savingProgress ? 'جارٍ حفظ التقدم...' : _completed ? 'تم إكمال الدرس' : 'وضع علامة مكتمل'),
              ),
              IconButton(
                iconSize: 42,
                onPressed: () => setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                }),
                icon: Icon(_controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
              ),
            ]);
          },
        ),
      ),
    ),
  );
}

class AcademyHome extends StatefulWidget {
  final bool isTeacher;
  const AcademyHome({super.key, required this.isTeacher});
  @override
  State<AcademyHome> createState() => _AcademyHomeState();
}

class _AcademyHomeState extends State<AcademyHome> {
  int selected = 0;
  bool english = false;
  String query = '';
  List<Course> remoteCourses = [];
  bool coursesLoading = true;
  late Future<List<Course>> learningCoursesFuture;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    learningCoursesFuture = _loadLearningCourses();
  }

  Future<List<Course>> _loadLearningCourses() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final enrollments = await supabase.from('enrollments')
        .select('course_id').eq('student_id', user.id);
    final ids = (enrollments as List)
        .map((row) => row['course_id'] as String?)
        .whereType<String>().toList();
    if (ids.isEmpty) return [];
    final rows = await supabase.from('courses')
        .select('id,title,description,level,status')
        .inFilter('id', ids)
        .order('created_at', ascending: false);
    return (rows as List).map((row) {
      final level = row['level'] as String? ?? 'beginner';
      return Course(
        row['title'] as String? ?? '',
        'دورة تعليمية',
        row['description'] as String? ?? '',
        'أكاديمية الويب',
        level == 'advanced' ? 'متقدم' : level == 'intermediate' ? 'متوسط' : 'مبتدئ',
        Icons.web_rounded, purple, 0,
        id: row['id'] as String?,
        status: row['status'] as String? ?? 'published',
      );
    }).toList();
  }

  Future<void> _loadCourses() async {
    try {
      final rows = await supabase.from('courses')
          .select('id,title,description,level,status')
          .order('created_at', ascending: false);
      final loaded = (rows as List).map((row) {
        final level = row['level'] as String? ?? 'beginner';
        return Course(
          row['title'] as String? ?? '',
          'دورة تعليمية',
          row['description'] as String? ?? '',
          'أكاديمية الويب',
          level == 'advanced' ? 'متقدم' : level == 'intermediate' ? 'متوسط' : 'مبتدئ',
          Icons.web_rounded, purple, 0,
          id: row['id'] as String?,
          status: row['status'] as String? ?? 'published',
        );
      }).toList();
      if (mounted) setState(() { remoteCourses = loaded; coursesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => coursesLoading = false);
    }
  }

  Future<void> _createCourse() async {
    final title = TextEditingController();
    final description = TextEditingController();
    String level = 'beginner';
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) => AlertDialog(
          title: const Text('إنشاء دورة جديدة'),
          content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان الدورة')),
            const SizedBox(height: 10),
            TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'وصف الدورة')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: level,
              decoration: const InputDecoration(labelText: 'المستوى'),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('مبتدئ')),
                DropdownMenuItem(value: 'intermediate', child: Text('متوسط')),
                DropdownMenuItem(value: 'advanced', child: Text('متقدم')),
              ],
              onChanged: (value) => refreshDialog(() => level = value ?? 'beginner'),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () async {
              if (title.text.trim().length < 3) return;
              try {
                await supabase.from('courses').insert({
                  'teacher_id': supabase.auth.currentUser!.id,
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'level': level,
                  'status': 'draft',
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } on PostgrestException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            }, child: const Text('حفظ الدورة')),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    if (created == true) {
      await _loadCourses();
      if (mounted) _message('تم إنشاء الدورة كمسودة. يمكنك إضافة الدروس قبل نشرها.');
    }
  }


  Future<void> _addLesson(Course course) async {
    if (course.id == null) return;
    final title = TextEditingController();
    final description = TextEditingController();
    PlatformFile? selectedVideo;
    bool saving = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('إضافة درس جديد'),
          content: SizedBox(width: 460, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان الدرس')),
            const SizedBox(height: 10),
            TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'وصف الدرس')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: saving ? null : () async {
                final picked = await FilePicker.platform.pickFiles(
                  type: FileType.custom, allowedExtensions: ['mp4', 'webm', 'mov'], allowMultiple: false, withData: true,
                );
                if (picked != null && picked.files.isNotEmpty) {
                  refresh(() => selectedVideo = picked.files.first);
                }
              },
              icon: const Icon(Icons.video_file_outlined),
              label: Text(selectedVideo == null ? 'اختيار فيديو (اختياري)' : selectedVideo!.name),
            ),
            if (selectedVideo != null)
              Text((selectedVideo!.size / (1024 * 1024)).toStringAsFixed(1) + ' MB',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ])),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (title.text.trim().length < 2) return;
                refresh(() => saving = true);
                try {
                  String? videoPath;
                  if (selectedVideo != null) {
                    final bytes = selectedVideo!.bytes;
                    if (bytes == null || bytes.isEmpty) {
                      throw Exception('تعذر قراءة ملف الفيديو من الجهاز.');
                    }
                    if (bytes.length > 524288000) {
                      throw Exception('حجم الفيديو يتجاوز حد 500 ميغابايت.');
                    }
                    final safeName = selectedVideo!.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
                    videoPath = course.id! + '/' + DateTime.now().microsecondsSinceEpoch.toString() + '_' + safeName;
                    await supabase.storage.from('course-videos').uploadBinary(
                      videoPath, bytes,
                      fileOptions: FileOptions(
                        contentType: selectedVideo!.extension?.toLowerCase() == 'webm'
                          ? 'video/webm'
                          : selectedVideo!.extension?.toLowerCase() == 'mov'
                            ? 'video/quicktime' : 'video/mp4',
                        upsert: false,
                      ),
                    );
                  }
                  final existing = await supabase.from('lessons')
                    .select('position').eq('course_id', course.id!)
                    .order('position', ascending: false).limit(1);
                  final nextPosition = existing.isEmpty ? 1 : (existing.first['position'] as int) + 1;
                  await supabase.from('lessons').insert({
                    'course_id': course.id,
                    'title': title.text.trim(),
                    'description': description.text.trim(),
                    'video_path': videoPath,
                    'position': nextPosition,
                    'is_preview': false,
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (dialogContext.mounted) {
                    refresh(() => saving = false);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('تعذر حفظ الدرس: ' + error.toString())),
                    );
                  }
                }
              },
              child: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('حفظ الدرس'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    if (result == true && mounted) _message('تمت إضافة الدرس إلى الدورة.');
  }

  Future<void> _publishCourse(Course course) async {
    if (course.id == null) return;
    try {
      await supabase.from('courses').update({'status': 'published'}).eq('id', course.id!);
      await _loadCourses();
      if (mounted) _message('تم نشر الدورة وأصبحت متاحة للطلاب.');
    } on PostgrestException catch (e) {
      if (mounted) _message(e.message);
    }
  }

  String t(String ar, String en) => english ? en : ar;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 850;
    return Directionality(
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.school_rounded, color: Colors.white)),
            const SizedBox(width: 10),
            Text(t('أكاديمية الويب', 'Web Academy'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
          actions: [
            TextButton.icon(onPressed: () => setState(() => english = !english),
              icon: const Icon(Icons.translate, size: 18), label: Text(english ? 'العربية' : 'EN')),
            const SizedBox(width: 8),
            Padding(padding: const EdgeInsetsDirectional.only(end: 14),
              child: CircleAvatar(backgroundColor: const Color(0xFFE8E7FF),
                child: Icon(widget.isTeacher ? Icons.cast_for_education : Icons.person, color: purple))),
          ],
        ),
        body: Row(children: [
          if (wide) _sideNav(),
          Expanded(child: _page()),
        ]),
        bottomNavigationBar: wide ? null : NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (v) => setState(() => selected = v),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.grid_view_rounded), label: t('الرئيسية', 'Home')),
            NavigationDestination(icon: const Icon(Icons.menu_book_rounded), label: t('الدورات', 'Courses')),
            NavigationDestination(icon: const Icon(Icons.play_circle_outline), label: t('تعلمي', 'Learning')),
            NavigationDestination(icon: const Icon(Icons.person_outline), label: t('حسابي', 'Profile')),
          ],
        ),
      ),
    );
  }

  Widget _sideNav() => Container(
    width: 230, color: Colors.white,
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 14),
      Text(t('مساحة التعلم', 'LEARNING SPACE'), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _navItem(0, Icons.grid_view_rounded, t('لوحة الرئيسية', 'Overview')),
      _navItem(1, Icons.menu_book_rounded, t('استكشاف الدورات', 'Explore courses')),
      _navItem(2, Icons.play_circle_outline, t('متابعة التعلم', 'My learning')),
      _navItem(3, Icons.person_outline, t('الملف الشخصي', 'Profile')),
      const Spacer(),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF0EFFF), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.auto_awesome, color: purple),
          const SizedBox(height: 8),
          Text(t('خطوتك القادمة تصنع الفرق!', 'Your next step matters!'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(t('واصل التعلم وابنِ مشروعك الأول.', 'Keep learning and build your first project.'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ])),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () async { await supabase.auth.signOut(); },
        icon: const Icon(Icons.logout),
        label: Text(t('تسجيل الخروج', 'Sign out'))),
    ]),
  );

  Widget _navItem(int index, IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: ListTile(selected: selected == index, selectedTileColor: const Color(0xFFF0EFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: selected == index ? purple : Colors.blueGrey),
      title: Text(label, style: TextStyle(fontWeight: selected == index ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      onTap: () => setState(() => selected = index)),
  );

  Widget _page() {
    if (selected == 1) return _coursesPage();
    if (selected == 2) return _learningPage();
    if (selected == 3) return _profilePage();
    return _dashboard();
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(24), children: [
    if (!widget.isTeacher) _hero(),
    if (widget.isTeacher) _teacherPanel(),
    const SizedBox(height: 26),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(t('دورات مقترحة لك', 'Recommended courses'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink)),
      TextButton(onPressed: () => setState(() => selected = 1), child: Text(t('عرض الكل', 'View all'))),
    ]),
    const SizedBox(height: 12),
    if (coursesLoading) const Center(child: CircularProgressIndicator()),
    if (!coursesLoading && remoteCourses.isEmpty) const Text('لا توجد دورات متاحة بعد.'),
    LayoutBuilder(builder: (context, c) {
      final count = c.maxWidth > 1050 ? 4 : c.maxWidth > 650 ? 2 : 1;
      return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: remoteCourses.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 220),
        itemBuilder: (_, i) => _courseCard(remoteCourses[i], i));
    }),
    const SizedBox(height: 22),
    _sectionTitle(t('رحلتك التعليمية', 'Your learning journey')),
    const SizedBox(height: 12),
    _statRow(),
  ]);

  Widget _hero() => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, Color(0xFF34346D)]),
      borderRadius: BorderRadius.circular(24)),
    child: LayoutBuilder(builder: (context, c) => Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(20)),
          child: Text(t('تعلم • طبّق • أبدع', 'LEARN • BUILD • CREATE'), style: const TextStyle(color: Colors.white, fontSize: 11))),
        const SizedBox(height: 16),
        Text(t('حوّل شغفك إلى\nمواقع ويب مذهلة', 'Turn your passion into\namazing websites'),
          style: const TextStyle(color: Colors.white, fontSize: 27, height: 1.35, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(t('ابدأ من الصفر، وتعلّم خطوة بخطوة حتى تنجز مشروعك الكامل.', 'Start from zero and build a complete project step by step.'),
          style: TextStyle(color: Colors.white.withValues(alpha: .78), height: 1.6)),
        const SizedBox(height: 18),
        FilledButton(onPressed: () => setState(() => selected = 1),
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: navy),
          child: Text(t('اكتشف الدورات', 'Explore courses'))),
      ])),
      if (c.maxWidth > 500) const SizedBox(width: 18),
      if (c.maxWidth > 500) Container(width: 130, height: 130,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.web_rounded, color: Colors.white, size: 76)),
    ])),
  );

  Widget _teacherPanel() => Container(padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(22)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.cast_for_education, color: Colors.white, size: 34),
      const SizedBox(height: 12),
      Text(t('لوحة المدرّس', 'Teacher dashboard'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(t('أدر محتواك التعليمي وتابع تقدم طلابك.', 'Manage your content and track student progress.'), style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _teacherAction(Icons.add, t('إنشاء دورة', 'Create course')),
        _teacherAction(Icons.video_call, t('إضافة فيديو', 'Add video')),
        _teacherAction(Icons.quiz, t('إنشاء اختبار', 'Create quiz')),
      ]),
    ]));

  Widget _teacherAction(IconData icon, String label) => OutlinedButton.icon(
    onPressed: () { if (icon == Icons.add) { _createCourse(); } else { _message(t('إضافة الدروس ورفع الفيديوهات ستكون الخطوة التالية.', 'Lesson creation and video uploads are next.')); } },
    icon: Icon(icon, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white)),
    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)));

  Widget _coursesPage() => ListView(padding: const EdgeInsets.all(24), children: [
    _sectionTitle(t('استكشف الدورات', 'Explore courses')),
    const SizedBox(height: 8),
    Text(t('مسارات عملية لتتعلم تصميم وتطوير الويب.', 'Practical paths to learn web design and development.'), style: const TextStyle(color: Colors.blueGrey)),
    const SizedBox(height: 18),
    TextField(onChanged: (v) => setState(() => query = v),
      decoration: InputDecoration(hintText: t('ابحث عن دورة...', 'Search courses...'), prefixIcon: const Icon(Icons.search),
        filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
    const SizedBox(height: 18),
    if (coursesLoading) const Center(child: CircularProgressIndicator()),
    if (!coursesLoading && remoteCourses.isEmpty) const Text('لا توجد دورات بعد. ستظهر هنا الدورات التي ينشرها المدرسون.'),
    ...remoteCourses.asMap().entries.where((e) => e.value.title.contains(query) || e.value.category.contains(query))
      .map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _courseCard(e.value, e.key))),
  ]);

  Widget _learningPage() => ListView(padding: const EdgeInsets.all(24), children: [
    _sectionTitle(t('متابعة التعلم', 'Continue learning')),
    const SizedBox(height: 8),
    Text(t('الدورات التي التحقت بها وحالة تعلمك.', 'Courses you joined and your learning progress.'), style: const TextStyle(color: Colors.blueGrey)),
    const SizedBox(height: 18),
    FutureBuilder<List<Course>>(
      future: learningCoursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const Text('تعذر تحميل دوراتك حالياً. حاول تحديث الصفحة.');
        }
        final enrolled = snapshot.data ?? [];
        if (enrolled.isEmpty) {
          return Card(
            elevation: 0,
            color: const Color(0xFFF7F7FC),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Icon(Icons.menu_book_outlined, size: 42, color: purple),
                const SizedBox(height: 10),
                Text(t('لم تلتحق بأي دورة بعد.', 'You have not joined a course yet.'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(t('استكشف الدورات المنشورة واختر ما يناسبك.',
                  'Explore published courses and choose one to start.')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => selected = 1),
                  icon: const Icon(Icons.explore_outlined),
                  label: Text(t('استكشاف الدورات', 'Explore courses')),
                ),
              ]),
            ),
          );
        }
        return Column(children: enrolled.asMap().entries.map((entry) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _courseCard(entry.value, entry.key),
          )).toList());
      },
    ),
  ]);

  Widget _profilePage() => ListView(padding: const EdgeInsets.all(24), children: [
    _sectionTitle(t('الملف الشخصي', 'Profile')),
    const SizedBox(height: 20),
    const CircleAvatar(radius: 38, backgroundColor: Color(0xFFE8E7FF), child: Icon(Icons.person, color: purple, size: 40)),
    const SizedBox(height: 12),
    Text(t('متعلم جديد', 'New learner'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    Text(t('عضو في أكاديمية تصميم الويب', 'Web Design Academy member'), style: const TextStyle(color: Colors.blueGrey)),
    const SizedBox(height: 24),
    ListTile(leading: const Icon(Icons.verified_user_outlined), title: Text(widget.isTeacher ? t('حساب مدرّس', 'Teacher account') : t('حساب طالب', 'Student account'))),
    ListTile(leading: const Icon(Icons.logout), title: Text(t('تسجيل الخروج', 'Sign out')),
      onTap: () async { await supabase.auth.signOut(); }),
    SwitchListTile(title: Text(t('English interface', 'الواجهة العربية')), value: english,
      onChanged: (v) => setState(() => english = v)),
  ]);

  Widget _courseCard(Course course, int index) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => _openCourse(course),
    child: Container(padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EAF1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(color: course.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)),
            child: Icon(course.icon, color: course.color)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFF2F3F8), borderRadius: BorderRadius.circular(20)),
            child: Text(course.level, style: const TextStyle(fontSize: 11, color: ink))),
        ]),
        const Spacer(),
        Text(course.category, style: TextStyle(color: course.color, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(course.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
        const SizedBox(height: 5),
        Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.menu_book_outlined, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 5),
          Text(course.duration, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          const Spacer(),
          if (course.progress > 0) Text('${(course.progress * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
        if (course.progress > 0) ...[
          const SizedBox(height: 7),
          LinearProgressIndicator(value: course.progress, minHeight: 5, borderRadius: BorderRadius.circular(10), color: course.color, backgroundColor: course.color.withValues(alpha: .12)),
        ],
      ]),
    ),
  );


  void _openCourse(Course course) {
    if (course.id == null) return;
    Future<List<Map<String, dynamic>>> lessonsFuture = supabase
      .from('lessons').select('id,title,description,video_path,is_preview,position')
      .eq('course_id', course.id!).order('position');
    Future<bool> enrollmentFuture = supabase.from('enrollments')
      .select('id').eq('course_id', course.id!)
      .eq('student_id', supabase.auth.currentUser!.id)
      .maybeSingle().then((row) => row != null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => Directionality(
          textDirection: english ? TextDirection.ltr : TextDirection.rtl,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  Row(children: [
                    Icon(course.icon, color: course.color, size: 30),
                    const SizedBox(width: 12),
                    Expanded(child: Text(course.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 12),
                  Text(course.description),
                  const SizedBox(height: 18),
                  if (widget.isTeacher) ...[
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      FilledButton.icon(
                        onPressed: () async {
                          await _addLesson(course);
                          refreshSheet(() {
                            lessonsFuture = supabase.from('lessons')
                              .select('id,title,description,video_path,is_preview,position')
                              .eq('course_id', course.id!).order('position');
                          });
                        },
                        icon: const Icon(Icons.add), label: const Text('إضافة درس'),
                      ),
                      if (course.status != 'published')
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _publishCourse(course);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.publish), label: const Text('نشر الدورة'),
                        ),
                    ]),
                    const SizedBox(height: 16),
                  ] else if (course.status == 'published')
                    FutureBuilder<bool>(
                      future: enrollmentFuture,
                      builder: (context, enrollment) {
                        if (!enrollment.hasData) return const LinearProgressIndicator();
                        if (enrollment.data == true) return const Chip(
                          avatar: Icon(Icons.check_circle, color: Colors.green),
                          label: Text('أنت مسجل في هذه الدورة'),
                        );
                        return FilledButton.icon(
                          onPressed: () async {
                            try {
                              await supabase.from('enrollments').insert({
                                'course_id': course.id,
                                'student_id': supabase.auth.currentUser!.id,
                              });
                              if (mounted) {
                                setState(() {
                                  learningCoursesFuture = _loadLearningCourses();
                                });
                              }
                              refreshSheet(() {
                                enrollmentFuture = Future.value(true);
                                lessonsFuture = supabase.from('lessons')
                                  .select('id,title,description,video_path,is_preview,position')
                                  .eq('course_id', course.id!).order('position');
                              });
                            } on PostgrestException catch (e) {
                              _message(e.message);
                            }
                          },
                          icon: const Icon(Icons.school_outlined),
                          label: const Text('التحق بالدورة'),
                        );
                      },
                    ),
                  const Divider(height: 28),
                  const Text('محتوى الدورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: lessonsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                      }
                      if (snapshot.hasError) return const Text('تعذر تحميل الدروس. تحقق من التسجيل وصلاحيات الدورة.');
                      final lessons = snapshot.data ?? [];
                      if (lessons.isEmpty) return const Text('لم تتم إضافة دروس لهذه الدورة بعد.');
                      return Column(children: lessons.map((lesson) => Card(
                        elevation: 0,
                        color: const Color(0xFFF7F7FC),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.play_arrow)),
                          title: Text(lesson['title'] as String? ?? 'درس'),
                          subtitle: Text((lesson['description'] as String? ?? '').isEmpty
                            ? (lesson['video_path'] == null ? 'درس نصي' : 'يتضمن فيديو')
                            : lesson['description'] as String),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () async {
                            final path = lesson['video_path'] as String?;
                            if (path == null || path.isEmpty) {
                              _message('هذا الدرس لا يحتوي على فيديو بعد.');
                              return;
                            }
                            try {
                              final url = await supabase.storage.from('course-videos')
                                .createSignedUrl(path, 3600);
                              if (!context.mounted) return;
                              final navigator = Navigator.of(sheetContext);
                              navigator.pop();
                              navigator.push(MaterialPageRoute(
                                builder: (_) => LessonPlayerScreen(
                                  title: lesson['title'] as String? ?? 'مشغل الدرس',
                                  videoUrl: url,
                                  lessonId: lesson['id'] as String,
                                ),
                              ));
                            } catch (error) {
                              _message('لا يمكن فتح الفيديو. تحقق من تسجيلك في الدورة.');
                            }
                          },
                        ),
                      )).toList());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lessonTile(String title, String subtitle, IconData icon) => ListTile(
    contentPadding: EdgeInsets.zero, leading: Container(width: 42, height: 42,
      decoration: BoxDecoration(color: const Color(0xFFF0EFFF), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: purple)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
    trailing: const Icon(Icons.chevron_left, color: Colors.blueGrey));

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink));

  Widget _statRow() => Wrap(spacing: 12, runSpacing: 12, children: [
    _stat(Icons.menu_book, '4', t('دورات متاحة', 'Courses')),
    _stat(Icons.check_circle_outline, '2', t('دروس مكتملة', 'Lessons done')),
    _stat(Icons.local_fire_department_outlined, '3', t('أيام متتالية', 'Day streak')),
  ]);

  Widget _stat(IconData icon, String value, String label) => Container(
    width: 170, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [Icon(icon, color: purple), const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
      ])]));

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
