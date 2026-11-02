import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _profileUserId;
  Future<Map<String, dynamic>?>? _profileFuture;

  Future<Map<String, dynamic>?> _loadProfile(String userId) async {
    final row = await supabase.from('profiles')
        .select('id,role,display_name').eq('id', userId).maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  void _retryProfile(String userId) {
    setState(() {
      _profileUserId = userId;
      _profileFuture = _loadProfile(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = supabase.auth.currentUser;
        if (user == null) {
          _profileUserId = null;
          _profileFuture = null;
          return const AuthScreen();
        }

        if (_profileUserId != user.id || _profileFuture == null) {
          _profileUserId = user.id;
          _profileFuture = _loadProfile(user.id);
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, profile) {
            if (profile.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profile.hasError || !profile.hasData || profile.data == null) {
              final missing = !profile.hasError && profile.data == null;
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 48, color: Colors.deepOrange),
                            const SizedBox(height: 14),
                            Text(
                              missing
                                  ? 'لم نعثر على ملف صلاحيات لهذا الحساب.'
                                  : 'تعذر التحقق من صلاحيات الحساب. لم يتم فتح التطبيق بصلاحيات افتراضية.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'حاول إعادة تحميل بيانات الحساب، أو سجّل الخروج ثم أعد تسجيل الدخول.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => _retryProfile(user.id),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('إعادة المحاولة'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => supabase.auth.signOut(),
                                  icon: const Icon(Icons.logout),
                                  label: const Text('تسجيل الخروج'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final role = profile.data!['role'] as String?;
            if (role == null || !['student', 'teacher', 'admin'].contains(role)) {
              return const Scaffold(
                body: Center(
                  child: Text('نوع الحساب غير معروف. يرجى التواصل مع إدارة الأكاديمية.'),
                ),
              );
            }
            return AcademyHome(
              isTeacher: role == 'teacher' || role == 'admin',
              role: role,
            );
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

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _show('أدخل بريدك الإلكتروني أولاً لإرسال رابط إعادة تعيين كلمة المرور.');
      return;
    }
    setState(() => _busy = true);
    try {
      await supabase.auth.resetPasswordForEmail(email);
      _show('إذا كان البريد مسجلاً، فسيصلك رابط إعادة تعيين كلمة المرور.');
    } on AuthException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('تعذر إرسال رابط إعادة التعيين. حاول مرة أخرى.');
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
                  if (!_register)
                    TextButton(
                      onPressed: _busy ? null : _resetPassword,
                      child: const Text('نسيت كلمة المرور؟'),
                    ),
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
  final bool allowProgress;
  const LessonPlayerScreen({super.key, required this.title, required this.videoUrl, required this.lessonId, this.allowProgress = true});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialize;
  bool _savingProgress = false;
  bool _completed = false;

  Future<void> _saveWatchPosition({bool completed = false, bool suppressErrors = false}) async {
    if (!widget.allowProgress) return;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('lesson_progress').upsert({
        'lesson_id': widget.lessonId,
        'student_id': user.id,
        'completed': completed || _completed,
        'watched_seconds': _controller.value.position.inSeconds,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'lesson_id,student_id');
    } catch (_) {
      if (!suppressErrors) rethrow;
    }
  }

  Future<void> _markCompleted() async {
    if (!widget.allowProgress || _savingProgress || _completed) return;
    setState(() => _savingProgress = true);
    try {
      await _saveWatchPosition(completed: true);
      if (mounted) setState(() => _completed = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ تقدمك في هذا الدرس.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ التقدم: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialize = _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _controller.initialize();
    if (!widget.allowProgress) return;
    try {
      final row = await supabase.from('lesson_progress')
          .select('completed,watched_seconds')
          .eq('lesson_id', widget.lessonId)
          .eq('student_id', supabase.auth.currentUser!.id)
          .maybeSingle();
      if (row == null) return;
      final seconds = (row['watched_seconds'] as num?)?.toInt() ?? 0;
      final duration = _controller.value.duration.inSeconds;
      if (seconds > 0 && seconds < duration && row['completed'] != true) {
        await _controller.seekTo(Duration(seconds: seconds));
      }
      _completed = row['completed'] == true;
    } catch (_) {
      // Video playback remains available even if progress history cannot load.
    }
  }

  @override
  void dispose() {
    if (widget.allowProgress) {
      unawaited(_saveWatchPosition(suppressErrors: true));
    }
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
              if (widget.allowProgress)
                FilledButton.icon(
                  onPressed: _savingProgress || _completed ? null : _markCompleted,
                  icon: Icon(_completed ? Icons.check_circle : Icons.task_alt),
                  label: Text(_savingProgress ? 'جارٍ حفظ التقدم...' : _completed ? 'تم إكمال الدرس' : 'وضع علامة مكتمل'),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('أنت تشاهد معاينة مجانية. سجّل في الدورة لحفظ تقدمك.'),
                ),
              IconButton(
                iconSize: 42,
                onPressed: () {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                    unawaited(_saveWatchPosition(suppressErrors: true));
                  } else {
                    _controller.play();
                  }
                  setState(() {});
                },
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
  final String role;
  const AcademyHome({super.key, required this.isTeacher, required this.role});
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
  late Future<Map<String, int>> dashboardStatsFuture;
  late Future<List<Map<String, dynamic>>> usersFuture;
  String usersQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();
    learningCoursesFuture = _loadLearningCourses();
    dashboardStatsFuture = _loadDashboardStats();
    usersFuture = widget.role == 'admin' ? _loadUsers() : Future.value([]);
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
    final lessonRows = await supabase.from('lessons')
        .select('id,course_id').inFilter('course_id', ids);
    final completedRows = await supabase.from('lesson_progress')
        .select('lesson_id').eq('student_id', user.id).eq('completed', true);
    final completedIds = (completedRows as List)
        .map((row) => row['lesson_id']?.toString()).whereType<String>().toSet();
    final lessonCounts = <String, int>{};
    final completedCounts = <String, int>{};
    for (final lesson in lessonRows as List) {
      final courseId = lesson['course_id']?.toString();
      final lessonId = lesson['id']?.toString();
      if (courseId == null || lessonId == null) continue;
      lessonCounts[courseId] = (lessonCounts[courseId] ?? 0) + 1;
      if (completedIds.contains(lessonId)) {
        completedCounts[courseId] = (completedCounts[courseId] ?? 0) + 1;
      }
    }
    return (rows as List).map((row) {
      final level = row['level'] as String? ?? 'beginner';
      final id = row['id'] as String?;
      final total = id == null ? 0 : (lessonCounts[id] ?? 0);
      final completed = id == null ? 0 : (completedCounts[id] ?? 0);
      final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0).toDouble();
      return Course(
        row['title'] as String? ?? '',
        'دورة تعليمية',
        row['description'] as String? ?? '',
        '$total درس',
        level == 'advanced' ? 'متقدم' : level == 'intermediate' ? 'متوسط' : 'مبتدئ',
        Icons.web_rounded, purple, progress,
        id: id,
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
      if (mounted) setState(() {
        remoteCourses = loaded;
        coursesLoading = false;
        dashboardStatsFuture = _loadDashboardStats();
      });
    } catch (_) {
      if (mounted) setState(() => coursesLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final rows = await supabase.from('profiles')
        .select('id,display_name,role,created_at')
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> _changeUserRole(String userId, String role) async {
    try {
      await supabase.rpc('set_academy_user_role', params: {
        'p_target_user_id': userId,
        'p_new_role': role,
      });
      if (!mounted) return;
      setState(() => usersFuture = _loadUsers());
      _message('تم تحديث صلاحية المستخدم.');
    } catch (error) {
      _message('تعذر تغيير الصلاحية: $error');
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
              initialValue: level,
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



  Future<void> _createQuiz({String? initialCourseId}) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    final ownedCourses = widget.role == 'admin'
      ? await supabase.from('courses').select('id,title').order('created_at', ascending: false)
      : await supabase.from('courses').select('id,title')
          .eq('teacher_id', currentUser.id).order('created_at', ascending: false);
    if (ownedCourses.isEmpty) {
      _message('أنشئ دورة أولاً قبل إنشاء اختبار.');
      return;
    }
    String? courseId = ownedCourses.any((c) => c['id'] == initialCourseId)
        ? initialCourseId
        : ownedCourses.first['id'] as String?;
    final title = TextEditingController();
    final prompt = TextEditingController();
    final options = List.generate(4, (_) => TextEditingController());
    final passingScoreController = TextEditingController(text: '50');
    final maxAttemptsController = TextEditingController();
    int correct = 0;
    bool saving = false;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('إنشاء اختبار'),
          content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: courseId,
                decoration: const InputDecoration(labelText: 'الدورة'),
                items: ownedCourses.map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['title'] as String, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: saving ? null : (v) => refresh(() => courseId = v),
              ),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان الاختبار')),
              const SizedBox(height: 10),
              TextField(controller: prompt, maxLines: 2, decoration: const InputDecoration(labelText: 'السؤال الأول')),
              const SizedBox(height: 8),
              ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: TextField(controller: options[i], decoration: InputDecoration(labelText: 'الخيار ${i + 1}')),
              )),
              DropdownButtonFormField<int>(
                initialValue: correct,
                decoration: const InputDecoration(labelText: 'الإجابة الصحيحة (للمدرّس فقط)'),
                items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('الخيار ${i + 1}'))),
                onChanged: saving ? null : (v) => refresh(() => correct = v ?? 0),
              ),
              const SizedBox(height: 12),
              TextField(controller: passingScoreController, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'درجة النجاح (%)', helperText: 'من 0 إلى 100')),
              TextField(controller: maxAttemptsController, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الحد الأقصى للمحاولات', helperText: 'اتركه فارغاً للمحاولات غير المحدودة')),
            ],
          ))),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: saving ? null : () async {
                final passingScore = int.tryParse(passingScoreController.text.trim());
                final maxAttemptsText = maxAttemptsController.text.trim();
                final maxAttempts = maxAttemptsText.isEmpty ? null : int.tryParse(maxAttemptsText);
                if (courseId == null || title.text.trim().isEmpty || prompt.text.trim().isEmpty ||
                    options.any((o) => o.text.trim().isEmpty)) {
                  _message('أكمل عنوان الاختبار والسؤال والخيارات الأربعة.');
                  return;
                }
                if (passingScore == null || passingScore < 0 || passingScore > 100) {
                  _message('درجة النجاح يجب أن تكون بين 0 و100.');
                  return;
                }
                if (maxAttemptsText.isNotEmpty && (maxAttempts == null || maxAttempts < 1 || maxAttempts > 50)) {
                  _message('عدد المحاولات يجب أن يكون بين 1 و50، أو اتركه فارغاً.');
                  return;
                }
                refresh(() => saving = true);
                try {
                  final quiz = await supabase.from('quizzes').insert({
                    'course_id': courseId,
                    'title': title.text.trim(),
                    'passing_score': passingScore,
                    'max_attempts': maxAttempts,
                  }).select('id').single();
                  try {
                    await supabase.from('quiz_questions').insert({
                      'quiz_id': quiz['id'],
                      'prompt': prompt.text.trim(),
                      'options': options.map((o) => o.text.trim()).toList(),
                      'correct_option': correct,
                      'position': 1,
                    });
                  } catch (_) {
                    await supabase.from('quizzes').delete().eq('id', quiz['id']);
                    rethrow;
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  refresh(() => saving = false);
                  _message('تعذر إنشاء الاختبار: $e');
                }
              },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('إنشاء الاختبار'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    prompt.dispose();
    passingScoreController.dispose();
    maxAttemptsController.dispose();
    for (final option in options) { option.dispose(); }
    if (created == true && mounted) _message('تم إنشاء الاختبار وإضافة السؤال الأول. يمكنك إضافة أسئلة أخرى من صفحة الدورة.');
  }

  Future<void> _addQuizQuestion(String quizId) async {
    final prompt = TextEditingController();
    final options = List.generate(4, (_) => TextEditingController());
    int correct = 0;
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('إضافة سؤال للاختبار'),
          content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: prompt, maxLines: 2, decoration: const InputDecoration(labelText: 'نص السؤال')),
              ...List.generate(4, (i) => TextField(controller: options[i], decoration: InputDecoration(labelText: 'الخيار ${i + 1}'))),
              DropdownButtonFormField<int>(
                initialValue: correct,
                decoration: const InputDecoration(labelText: 'الإجابة الصحيحة'),
                items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('الخيار ${i + 1}'))),
                onChanged: (v) => refresh(() => correct = v ?? 0),
              ),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () async {
              if (prompt.text.trim().isEmpty || options.any((o) => o.text.trim().isEmpty)) {
                _message('أكمل السؤال والخيارات الأربعة.');
                return;
              }
              try {
                final existing = await supabase.from('quiz_questions').select('position')
                  .eq('quiz_id', quizId).order('position', ascending: false).limit(1);
                final position = existing.isEmpty ? 1 : (existing.first['position'] as int) + 1;
                await supabase.from('quiz_questions').insert({
                  'quiz_id': quizId, 'prompt': prompt.text.trim(),
                  'options': options.map((o) => o.text.trim()).toList(),
                  'correct_option': correct, 'position': position,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (e) { _message('تعذر إضافة السؤال: $e'); }
            }, child: const Text('حفظ السؤال')),
          ],
        ),
      ),
    );
    prompt.dispose();
    for (final option in options) { option.dispose(); }
    if (added == true && mounted) _message('تمت إضافة السؤال.');
  }

  Future<void> _editQuizSettings(Map<String, dynamic> quiz) async {
    final quizId = quiz['id'] as String;
    final title = TextEditingController(text: quiz['title']?.toString() ?? '');
    final passingScore = TextEditingController(text: (quiz['passing_score'] as num?)?.toInt().toString() ?? '50');
    final maxAttempts = TextEditingController(text: (quiz['max_attempts'] as num?)?.toInt().toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إعدادات الاختبار'),
        content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, maxLength: 100,
            decoration: const InputDecoration(labelText: 'عنوان الاختبار')),
          TextField(controller: passingScore, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'درجة النجاح (%)', helperText: 'من 0 إلى 100')),
          TextField(controller: maxAttempts, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الحد الأقصى للمحاولات', helperText: 'اتركه فارغاً للمحاولات غير المحدودة')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final pass = int.tryParse(passingScore.text.trim());
              final maxText = maxAttempts.text.trim();
              final max = maxText.isEmpty ? null : int.tryParse(maxText);
              if (title.text.trim().length < 2) {
                _message('أدخل عنواناً صحيحاً للاختبار.');
                return;
              }
              if (pass == null || pass < 0 || pass > 100) {
                _message('درجة النجاح يجب أن تكون بين 0 و100.');
                return;
              }
              if (maxText.isNotEmpty && (max == null || max < 1 || max > 50)) {
                _message('عدد المحاولات يجب أن يكون بين 1 و50، أو اتركه فارغاً.');
                return;
              }
              try {
                await supabase.from('quizzes').update({
                  'title': title.text.trim(),
                  'passing_score': pass,
                  'max_attempts': max,
                }).eq('id', quizId);
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                _message('تعذر حفظ إعدادات الاختبار: $error');
              }
            },
            child: const Text('حفظ الإعدادات'),
          ),
        ],
      ),
    );
    title.dispose();
    passingScore.dispose();
    maxAttempts.dispose();
    if (saved == true && mounted) _message('تم تحديث إعدادات الاختبار.');
  }

  Future<void> _editQuizQuestion(Map<String, dynamic> question) async {
    final id = question['id'] as String?;
    if (id == null) return;
    final prompt = TextEditingController(text: question['prompt']?.toString() ?? '');
    final currentOptions = (question['options'] as List? ?? const [])
        .map((value) => value.toString()).toList();
    final options = currentOptions.map((value) => TextEditingController(text: value)).toList();
    int correct = (question['correct_option'] as num?)?.toInt() ?? 0;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('تعديل السؤال'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: prompt, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'نص السؤال')),
                const SizedBox(height: 8),
                ...options.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TextField(controller: entry.value,
                    decoration: InputDecoration(labelText: 'الخيار ${entry.key + 1}')),
                )),
                DropdownButtonFormField<int>(
                  initialValue: correct < 0 || correct >= options.length ? 0 : correct,
                  decoration: const InputDecoration(labelText: 'الإجابة الصحيحة'),
                  items: List.generate(options.length, (i) =>
                    DropdownMenuItem(value: i, child: Text('الخيار ${i + 1}'))),
                  onChanged: (value) => refresh(() => correct = value ?? 0),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                if (prompt.text.trim().isEmpty || options.length < 2 ||
                    options.any((option) => option.text.trim().isEmpty)) {
                  _message('أكمل نص السؤال وجميع الخيارات.');
                  return;
                }
                try {
                  await supabase.from('quiz_questions').update({
                    'prompt': prompt.text.trim(),
                    'options': options.map((option) => option.text.trim()).toList(),
                    'correct_option': correct,
                  }).eq('id', id);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  _message('تعذر تعديل السؤال: $error');
                }
              },
              child: const Text('حفظ السؤال'),
            ),
          ],
        ),
      ),
    );
    prompt.dispose();
    for (final option in options) {
      option.dispose();
    }
    if (saved == true && mounted) _message('تم تحديث السؤال.');
  }

  Future<void> _manageQuizQuestions(String quizId, String quizTitle) async {
    Future<List<Map<String, dynamic>>> loadQuestions() async {
      final rows = await supabase.from('quiz_questions')
          .select('id,prompt,options,correct_option,position')
          .eq('quiz_id', quizId).order('position');
      return (rows as List).map((row) => Map<String, dynamic>.from(row)).toList();
    }

    var questionsFuture = loadQuestions();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('أسئلة: $quizTitle'),
          content: SizedBox(
            width: 560,
            height: 360,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: questionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const Text('تعذر تحميل أسئلة الاختبار.');
                }
                final questions = snapshot.data ?? [];
                if (questions.isEmpty) {
                  return const Text('لا توجد أسئلة في هذا الاختبار.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final opts = (question['options'] as List? ?? const []);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(question['prompt']?.toString() ?? 'سؤال'),
                      subtitle: Text('${opts.length} خيارات'),
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: 'تعديل السؤال',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              await _editQuizQuestion(question);
                              if (dialogContext.mounted) {
                                refresh(() => questionsFuture = loadQuestions());
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'حذف السؤال',
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: dialogContext,
                                builder: (confirmContext) => AlertDialog(
                                  title: const Text('حذف السؤال'),
                                  content: const Text('هل تريد حذف هذا السؤال نهائياً؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(confirmContext, false),
                                      child: const Text('إلغاء'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(confirmContext, true),
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              try {
                                await supabase.from('quiz_questions')
                                    .delete().eq('id', question['id']);
                                if (dialogContext.mounted) {
                                  refresh(() => questionsFuture = loadQuestions());
                                }
                              } catch (error) {
                                _message('تعذر حذف السؤال: $error');
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQuiz(String quizId) async {
    try {
      final raw = await supabase.rpc('get_quiz_for_student', params: {'p_quiz_id': quizId});
      final quiz = Map<String, dynamic>.from(raw as Map);
      final questions = (quiz['questions'] as List).map((q) => Map<String, dynamic>.from(q as Map)).toList();
      if (questions.isEmpty) { _message('لم تتم إضافة أسئلة لهذا الاختبار بعد.'); return; }
      final maxAttempts = (quiz['max_attempts'] as num?)?.toInt();
      final attemptsRemaining = (quiz['attempts_remaining'] as num?)?.toInt();
      final passingScore = (quiz['passing_score'] as num?)?.toInt() ?? 50;
      if (maxAttempts != null && (attemptsRemaining ?? 0) <= 0) {
        _message('لقد استنفدت جميع محاولات هذا الاختبار.');
        return;
      }
      final answers = <String, int>{};
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: Text(quiz['title'] as String? ?? 'الاختبار'),
            content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: const Color(0xFFF0EFFF),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'درجة النجاح: $passingScore%'
                      '${maxAttempts == null ? ' • المحاولات غير محدودة' : ' • المتبقي: ${attemptsRemaining ?? 0} من $maxAttempts'}',
                    ),
                  ),
                ),
                ...questions.asMap().entries.map((entry) {
                final q = entry.value;
                final opts = (q['options'] as List).map((v) => v.toString()).toList();
                final id = q['id'].toString();
                return Card(
                  elevation: 0, color: const Color(0xFFF7F7FC),
                  child: Padding(padding: const EdgeInsets.all(12), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key + 1}. ${q['prompt']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      RadioGroup<int>(
                        groupValue: answers[id],
                        onChanged: (value) => refresh(() {
                          if (value != null) answers[id] = value;
                        }),
                        child: Column(
                          children: List.generate(opts.length, (i) => RadioListTile<int>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(opts[i]),
                            value: i,
                          )),
                        ),
                      ),
                    ],
                  )),
                );
              }).toList(),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
              FilledButton(
                onPressed: answers.length != questions.length ? null : () async {
                  try {
                    final response = await supabase.rpc('submit_quiz_attempt', params: {
                      'p_quiz_id': quizId, 'p_answers': answers,
                    });
                    if (dialogContext.mounted) Navigator.pop(dialogContext, Map<String, dynamic>.from(response as Map));
                  } catch (e) {
                    _message('تعذر تسليم الاختبار: $e');
                  }
                },
                child: const Text('تسليم الإجابات'),
              ),
            ],
          ),
        ),
      );
      if (result != null && mounted) {
        final score = (result['score'] as num?)?.toStringAsFixed(2) ?? '0';
        final passed = result['passed'] == true;
        _message(
          '${passed ? 'تهانينا، لقد اجتزت الاختبار!' : 'لم تصل إلى درجة النجاح بعد، حاول مجدداً.'} '
          'نتيجتك: $score% — الإجابات الصحيحة ${result['correct_answers']} من ${result['total_questions']}.',
        );
      }
    } catch (e) {
      _message('تعذر فتح الاختبار. تأكد من الالتحاق بالدورة المنشورة. $e');
    }
  }


  Future<void> _editDisplayName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final currentName = user.userMetadata?['display_name']?.toString() ?? '';
    final name = TextEditingController(text: currentName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الاسم الظاهر'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: name,
            autofocus: true,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'الاسم الظاهر'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final value = name.text.trim();
              if (value.length < 2) {
                _message('أدخل اسماً يتكون من حرفين على الأقل.');
                return;
              }
              try {
                await supabase.from('profiles').update({
                  'display_name': value,
                }).eq('id', user.id);
                await supabase.auth.updateUser(
                  UserAttributes(data: {'display_name': value}),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                _message('تعذر تحديث الاسم: $error');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    name.dispose();
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _showMyQuizHistory() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final raw = await supabase.rpc('get_my_quiz_history');
      final rows = (raw as List)
          .map((row) => Map<String, dynamic>.from(row as Map)).toList();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('سجل نتائج اختباراتي'),
          content: SizedBox(
            width: 520,
            child: rows.isEmpty
              ? const Text('لم تسلّم أي اختبار بعد.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final score = (row['score'] as num?)?.toStringAsFixed(2) ?? '—';
                    final date = DateTime.tryParse(row['submitted_at']?.toString() ?? '');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8E7FF),
                        child: Text(score == '—' ? '—' : '${(double.tryParse(score) ?? 0).round()}%'),
                      ),
                      title: Text(row['quiz_title']?.toString() ?? 'اختبار'),
                      subtitle: Text('${date == null ? 'تاريخ غير متاح' : date.toLocal().toString().substring(0, 16)} • ${row['passed'] == true ? 'ناجح' : 'لم يجتز'}'),
                      trailing: Text('$score%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
        ),
      );
    } catch (e) {
      _message('تعذر تحميل سجل الاختبارات: $e');
    }
  }

  Future<void> _showCourseStudents(String courseId, String courseTitle) async {
    try {
      final raw = await supabase.rpc(
        'get_course_students',
        params: {'p_course_id': courseId},
      );
      final rows = (raw as List)
          .map((row) => Map<String, dynamic>.from(row as Map)).toList();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('طلاب دورة: $courseTitle'),
          content: SizedBox(
            width: 560,
            child: rows.isEmpty
                ? const Text('لم يلتحق أي طالب بهذه الدورة بعد.')
                : SizedBox(
                    height: 360,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                      final row = rows[index];
                      final completed = (row['completed_lessons'] as num?)?.toInt() ?? 0;
                      final total = (row['total_lessons'] as num?)?.toInt() ?? 0;
                      final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0).toDouble();
                      final date = DateTime.tryParse(row['enrolled_at']?.toString() ?? '');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                        title: Text(row['student_name']?.toString() ?? 'طالب'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(date == null
                                ? 'تاريخ التسجيل غير متاح'
                                : 'تاريخ التسجيل: ${date.toLocal().toString().substring(0, 10)}'),
                            const SizedBox(height: 5),
                            Text('الدروس المكتملة: $completed من $total'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: progress, minHeight: 5),
                          ],
                        ),
                        trailing: Text('${(progress * 100).round()}%'),
                      );
                      },
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (error) {
      _message('تعذر تحميل قائمة الطلاب: $error');
    }
  }

  Future<void> _showQuizResults(String quizId, String quizTitle) async {
    try {
      final raw = await supabase.rpc('get_quiz_results_for_teacher', params: {'p_quiz_id': quizId});
      final rows = (raw as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
      final scores = rows.map((row) => (row['score'] as num?)?.toDouble() ?? 0).toList();
      final average = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
      final passedCount = rows.where((row) => row['passed'] == true).length;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('نتائج: $quizTitle'),
          content: SizedBox(
            width: 560,
            child: rows.isEmpty
                ? const Text('لم يقدّم أي طالب هذا الاختبار بعد.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.people_outline, size: 18),
                            label: Text('${rows.length} محاولة'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.trending_up, size: 18),
                            label: Text('المتوسط ${average.toStringAsFixed(1)}%'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.check_circle_outline, size: 18),
                            label: Text('اجتاز ${passedCount}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 360,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final score = (row['score'] as num?)?.toStringAsFixed(2) ?? '—';
                            final date = DateTime.tryParse(row['submitted_at']?.toString() ?? '');
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                              title: Text(row['student_name']?.toString() ?? 'طالب'),
                              subtitle: Text(date == null ? 'تاريخ غير متاح' : date.toLocal().toString().substring(0, 16)),
                              trailing: Text('$score%', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: row['passed'] == true ? Colors.green : Colors.deepOrange,
                              )),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
        ),
      );
    } catch (e) {
      _message('تعذر تحميل النتائج. تحقق من ملكيتك للدورة. $e');
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
                String? uploadedVideoPath;
                try {
                  if (selectedVideo != null) {
                    final bytes = selectedVideo!.bytes;
                    if (bytes == null || bytes.isEmpty) {
                      throw Exception('تعذر قراءة ملف الفيديو من الجهاز.');
                    }
                    if (bytes.length > 524288000) {
                      throw Exception('حجم الفيديو يتجاوز حد 500 ميغابايت.');
                    }
                    final extension = selectedVideo!.extension?.toLowerCase() ?? '';
                    if (!['mp4', 'webm', 'mov'].contains(extension)) {
                      throw Exception('صيغة الفيديو غير مدعومة. استخدم MP4 أو WebM أو MOV.');
                    }
                    final safeName = selectedVideo!.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
                    uploadedVideoPath = course.id! + '/' + DateTime.now().microsecondsSinceEpoch.toString() + '_' + safeName;
                    await supabase.storage.from('course-videos').uploadBinary(
                      uploadedVideoPath, bytes,
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
                    'video_path': uploadedVideoPath,
                    'position': nextPosition,
                    'is_preview': false,
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (uploadedVideoPath != null) {
                    try {
                      await supabase.storage.from('course-videos').remove([uploadedVideoPath]);
                    } catch (_) {
                      // Preserve the original error; an orphaned object can be cleaned up later.
                    }
                  }
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

  Future<void> _editCourse(Course course) async {
    if (course.id == null) return;
    final title = TextEditingController(text: course.title);
    final description = TextEditingController(text: course.description);
    String level = course.level == 'متقدم'
        ? 'advanced'
        : course.level == 'متوسط' ? 'intermediate' : 'beginner';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('تعديل بيانات الدورة'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: title,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'عنوان الدورة'),
                ),
                TextField(
                  controller: description,
                  maxLines: 4,
                  maxLength: 1200,
                  decoration: const InputDecoration(labelText: 'وصف الدورة'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'المستوى'),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('مبتدئ')),
                    DropdownMenuItem(value: 'intermediate', child: Text('متوسط')),
                    DropdownMenuItem(value: 'advanced', child: Text('متقدم')),
                  ],
                  onChanged: (value) => refresh(() => level = value ?? level),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().length < 3) {
                  _message('يجب أن يتكون عنوان الدورة من 3 أحرف على الأقل.');
                  return;
                }
                try {
                  await supabase.from('courses').update({
                    'title': title.text.trim(),
                    'description': description.text.trim(),
                    'level': level,
                  }).eq('id', course.id!);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  _message('تعذر تحديث الدورة: $error');
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    if (saved == true && mounted) {
      await _loadCourses();
      setState(() {
        learningCoursesFuture = _loadLearningCourses();
        dashboardStatsFuture = _loadDashboardStats();
      });
      _message('تم تحديث بيانات الدورة.');
    }
  }

  Future<void> _archiveCourse(Course course) async {
    if (course.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('أرشفة الدورة'),
        content: Text('هل تريد أرشفة «${course.title}»؟ لن تظهر الدورة ضمن الدورات المنشورة للطلاب.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('أرشفة الدورة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await supabase.from('courses')
          .update({'status': 'archived'}).eq('id', course.id!);
      await _loadCourses();
      if (mounted) _message('تمت أرشفة الدورة.');
    } catch (error) {
      _message('تعذرت أرشفة الدورة: $error');
    }
  }

  Future<void> _moveLesson(String courseId, String lessonId, int direction) async {
    try {
      final rows = await supabase.from('lessons')
          .select('id,position').eq('course_id', courseId).order('position');
      final lessons = (rows as List).map((row) => Map<String, dynamic>.from(row)).toList();
      final index = lessons.indexWhere((row) => row['id'] == lessonId);
      final targetIndex = index + direction;
      if (index < 0 || targetIndex < 0 || targetIndex >= lessons.length) return;
      final current = lessons[index];
      final target = lessons[targetIndex];
      final currentPosition = (current['position'] as num).toInt();
      final targetPosition = (target['position'] as num).toInt();
      await supabase.from('lessons').update({
        'position': -currentPosition - 1,
      }).eq('id', lessonId);
      try {
        await supabase.from('lessons').update({
          'position': currentPosition,
        }).eq('id', target['id']);
        await supabase.from('lessons').update({
          'position': targetPosition,
        }).eq('id', lessonId);
      } catch (_) {
        await supabase.from('lessons').update({
          'position': targetPosition,
        }).eq('id', target['id']);
        await supabase.from('lessons').update({
          'position': currentPosition,
        }).eq('id', lessonId);
        rethrow;
      }
      if (mounted) _message('تم تغيير ترتيب الدرس.');
    } catch (error) {
      _message('تعذر تغيير ترتيب الدرس: $error');
    }
  }

  Future<void> _deleteLesson(Map<String, dynamic> lesson) async {
    final lessonId = lesson['id'] as String?;
    if (lessonId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الدرس'),
        content: Text('سيُحذف الدرس «${lesson['title'] ?? ''}» وسجل تقدم الطلاب المرتبط به. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف الدرس'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final path = lesson['video_path']?.toString();
    try {
      await supabase.from('lessons').delete().eq('id', lessonId);
      if (path != null && path.isNotEmpty) {
        try {
          await supabase.storage.from('course-videos').remove([path]);
        } catch (_) {
          _message('حُذف الدرس، لكن تعذر حذف ملف الفيديو من التخزين.');
        }
      }
      if (mounted) _message('تم حذف الدرس.');
    } catch (error) {
      _message('تعذر حذف الدرس: $error');
    }
  }

  Future<void> _editLesson(Map<String, dynamic> lesson) async {
    final lessonId = lesson['id'] as String?;
    if (lessonId == null) return;
    final title = TextEditingController(text: lesson['title']?.toString() ?? '');
    final description = TextEditingController(text: lesson['description']?.toString() ?? '');
    bool isPreview = lesson['is_preview'] == true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('تعديل الدرس'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: title, maxLength: 100,
                decoration: const InputDecoration(labelText: 'عنوان الدرس')),
              TextField(controller: description, maxLines: 3, maxLength: 1000,
                decoration: const InputDecoration(labelText: 'وصف الدرس')),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: isPreview,
                onChanged: (value) => refresh(() => isPreview = value ?? false),
                title: const Text('إتاحة الدرس كمعاينة مجانية'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().length < 2) {
                  _message('أدخل عنواناً صحيحاً للدرس.');
                  return;
                }
                try {
                  await supabase.from('lessons').update({
                    'title': title.text.trim(),
                    'description': description.text.trim(),
                    'is_preview': isPreview,
                  }).eq('id', lessonId);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  _message('تعذر تعديل الدرس: $error');
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    if (saved == true && mounted) _message('تم تحديث الدرس.');
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
            NavigationDestination(icon: const Icon(Icons.workspace_premium_outlined), label: t('شهاداتي', 'Certificates')),
            if (widget.role == 'admin')
              NavigationDestination(icon: const Icon(Icons.manage_accounts_outlined), label: t('المستخدمون', 'Users')),
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
      _navItem(4, Icons.workspace_premium_outlined, t('شهاداتي', 'My certificates')),
      if (widget.role == 'admin')
        _navItem(5, Icons.manage_accounts_outlined, t('إدارة المستخدمين', 'User management')),
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
    if (selected == 4) return _certificatesPage();
    if (selected == 5 && widget.role == 'admin') return _usersPage();
    return _dashboard();
  }

  Widget _usersPage() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      _sectionTitle(t('إدارة المستخدمين', 'User management')),
      const SizedBox(height: 8),
      Text(
        t('غيّر أدوار الحسابات من لوحة المدير. لا يمكن إزالة صلاحية آخر مدير في النظام.',
          'Manage account roles. The last administrator cannot be demoted.'),
        style: const TextStyle(color: Colors.blueGrey),
      ),
      const SizedBox(height: 16),
      TextField(
        onChanged: (value) => setState(() => usersQuery = value.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: t('ابحث بالاسم أو معرّف الحساب...', 'Search name or user ID...'),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return const Text('تعذر تحميل المستخدمين. تأكد من صلاحيات المدير واتصال قاعدة البيانات.');
          }
          final allUsers = snapshot.data ?? [];
          final users = allUsers.where((user) {
            final name = user['display_name']?.toString().toLowerCase() ?? '';
            final id = user['id']?.toString().toLowerCase() ?? '';
            return usersQuery.isEmpty || name.contains(usersQuery) || id.contains(usersQuery);
          }).toList();
          final students = allUsers.where((user) => user['role'] == 'student').length;
          final teachers = allUsers.where((user) => user['role'] == 'teacher').length;
          final admins = allUsers.where((user) => user['role'] == 'admin').length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                Chip(label: Text('الإجمالي: ${allUsers.length}')),
                Chip(label: Text('طلاب: $students')),
                Chip(label: Text('مدرّسون: $teachers')),
                Chip(label: Text('مديرون: $admins')),
              ]),
              const SizedBox(height: 10),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لا توجد حسابات مطابقة لبحثك.'),
                ),
              ...users.map((user) {
                final id = user['id']?.toString() ?? '';
                final role = user['role']?.toString() ?? 'student';
                final name = user['display_name']?.toString().trim();
                final roleName = role == 'admin' ? 'مدير' : role == 'teacher' ? 'مدرّس' : 'طالب';
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8E7FF),
                      child: Icon(
                        role == 'admin' ? Icons.admin_panel_settings
                            : role == 'teacher' ? Icons.cast_for_education : Icons.person_outline,
                        color: purple,
                      ),
                    ),
                    title: Text(name?.isNotEmpty == true ? name! : 'مستخدم الأكاديمية'),
                    subtitle: Text('$roleName • ${id.length > 12 ? id.substring(0, 12) : id}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'تغيير الصلاحية',
                      onSelected: (value) => _changeUserRole(id, value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'student', child: Text('طالب')),
                        PopupMenuItem(value: 'teacher', child: Text('مدرّس')),
                        PopupMenuItem(value: 'admin', child: Text('مدير')),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.more_vert),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    ],
  );

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
    onPressed: () {
      if (icon == Icons.add) { _createCourse(); }
      else if (icon == Icons.quiz) { _createQuiz(); }
      else { _message(t('افتح الدورة لإضافة الدروس ورفع الفيديوهات.', 'Open a course to add lessons and videos.')); }
    },
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

  Future<List<Map<String, dynamic>>> _loadMyCertificates() async {
    final raw = await supabase.rpc('get_my_course_certificates');
    return (raw as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  String _certificateHtmlEscape(Object? value) {
    return (value?.toString() ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  void _printCertificate(Map<String, dynamic> certificate) {
    final student = _certificateHtmlEscape(certificate['student_name']);
    final course = _certificateHtmlEscape(certificate['course_title']);
    final code = _certificateHtmlEscape(certificate['certificate_code']);
    final issuedAt = DateTime.tryParse(certificate['issued_at']?.toString() ?? '');
    final issued = _certificateHtmlEscape(
      issuedAt == null
          ? '—'
          : '${issuedAt.toLocal().year}-${issuedAt.toLocal().month.toString().padLeft(2, '0')}-${issuedAt.toLocal().day.toString().padLeft(2, '0')}',
    );
    final printWindow = html.window.open('', '_blank');
    if (printWindow == null) {
      _message('اسمح بالنوافذ المنبثقة لتنزيل الشهادة بصيغة PDF.');
      return;
    }
    printWindow.document?.write('''
<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>شهادة إتمام - $course</title>
<style>
  @page { size: A4 landscape; margin: 10mm; }
  * { box-sizing: border-box; }
  body { margin: 0; background: #eef0f7; color: #17243b;
    font-family: Tahoma, Arial, sans-serif; }
  .sheet { width: 277mm; min-height: 190mm; margin: 12mm auto;
    padding: 13mm; background: #fff; border: 3px solid #6c63ff;
    outline: 1px solid #c8c4ff; outline-offset: -8px; position: relative;
    display: flex; flex-direction: column; align-items: center; text-align: center; }
  .brand { color: #6c63ff; font-size: 17px; font-weight: 800; letter-spacing: 2px; }
  .seal { width: 72px; height: 72px; margin: 12px auto 5px; border: 2px solid #d7b76b;
    border-radius: 50%; display: grid; place-items: center; color: #b18b36; font-size: 36px; }
  h1 { margin: 8px 0 12px; font-size: 36px; color: #17243b; }
  .intro { font-size: 17px; color: #64708a; margin: 5px 0; }
  .student { font-size: 32px; color: #6c63ff; font-weight: 800; margin: 12px 0; }
  .course { font-size: 23px; font-weight: 700; margin: 5px 0 12px; }
  .meta { display: flex; gap: 30px; margin-top: auto; width: 100%; justify-content: space-between;
    border-top: 1px solid #e5e7ef; padding-top: 14px; font-size: 13px; color: #5d6880; }
  .code { direction: ltr; font-family: monospace; letter-spacing: 2px; color: #17243b; font-weight: 800; }
  .footer { margin-top: 14px; font-size: 11px; color: #788198; }
  @media print { body { background: white; } .sheet { margin: 0; width: 100%; min-height: 185mm;
    -webkit-print-color-adjust: exact; print-color-adjust: exact; } }
</style>
</head>
<body>
<main class="sheet">
  <div class="brand">WEB DESIGN ACADEMY</div>
  <div class="seal">✦</div>
  <h1>شهادة إتمام دورة</h1>
  <p class="intro">تشهد أكاديمية تصميم الويب بأن المتعلم / المتعلمة</p>
  <div class="student">$student</div>
  <p class="intro">قد أتم بنجاح المتطلبات التعليمية للدورة</p>
  <div class="course">$course</div>
  <p class="intro">وذلك بعد إكمال الدروس واجتياز الاختبارات المطلوبة.</p>
  <section class="meta">
    <div><strong>تاريخ الإصدار</strong><br>$issued</div>
    <div><strong>رمز التحقق</strong><br><span class="code">$code</span></div>
    <div><strong>الجهة المصدرة</strong><br>أكاديمية تصميم الويب</div>
  </section>
  <div class="footer">يمكن التحقق من صحة هذه الشهادة باستخدام رمز التحقق من داخل الأكاديمية.</div>
</main>
<script>window.onload = function () { window.focus(); window.print(); };</script>
</body>
</html>
''');
    printWindow.document?.close();
  }

  Future<void> _issueCertificate(Course course) async {
    if (course.id == null) return;
    try {
      final raw = await supabase.rpc('issue_course_certificate', params: {
        'p_course_id': course.id,
      });
      final certificate = Map<String, dynamic>.from(raw as Map);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.workspace_premium, color: purple, size: 42),
          title: const Text('تم إصدار شهادتك'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(certificate['course_title']?.toString() ?? course.title,
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SelectableText(certificate['certificate_code']?.toString() ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('احتفظ برمز الشهادة للتحقق من صحتها لاحقاً.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
          ]),
          actions: [
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(
                text: certificate['certificate_code']?.toString() ?? '')),
              icon: const Icon(Icons.copy), label: const Text('نسخ الرمز')),
            FilledButton.tonalIcon(
              onPressed: () => _printCertificate(certificate),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('طباعة / PDF')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق')),
          ],
        ),
      );
      if (mounted) setState(() {});
    } catch (error) {
      final message = error is PostgrestException ? error.message : error.toString();
      _message('لم تصدر الشهادة بعد: $message');
    }
  }

  Future<void> _verifyCertificateDialog() async {
    final code = TextEditingController();
    Map<String, dynamic>? result;
    bool loading = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('التحقق من شهادة'),
          content: SizedBox(width: 420, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل رمز الشهادة للتحقق من أنها صادرة عن الأكاديمية.'),
              const SizedBox(height: 12),
              TextField(controller: code, textCapitalization: TextCapitalization.characters,
                onChanged: (_) => refresh(() {}),
                decoration: const InputDecoration(labelText: 'رمز الشهادة', hintText: 'WDA-XXXXXXXXXXXX')),
              if (loading) const Padding(padding: EdgeInsets.all(12),
                child: CircularProgressIndicator()),
              if (result != null) ...[
                const SizedBox(height: 12),
                if (result!['valid'] == true) ...[
                  const Icon(Icons.verified, color: Colors.green, size: 34),
                  const Text('الشهادة صحيحة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('الطالب: ${result!['student_name'] ?? '—'}'),
                  Text('الدورة: ${result!['course_title'] ?? '—'}'),
                  Text('تاريخ الإصدار: ${result!['issued_at'] ?? '—'}'),
                ] else
                  const Text('لم نعثر على شهادة بهذا الرمز.', style: TextStyle(color: Colors.deepOrange)),
              ],
            ],
          )),
          actions: [
            TextButton(onPressed: loading ? null : () => Navigator.pop(dialogContext),
              child: const Text('إغلاق')),
            FilledButton(
              onPressed: loading || code.text.trim().isEmpty ? null : () async {
                refresh(() { loading = true; result = null; });
                try {
                  final raw = await supabase.rpc('verify_course_certificate', params: {
                    'p_certificate_code': code.text.trim(),
                  });
                  if (dialogContext.mounted) refresh(() {
                    result = Map<String, dynamic>.from(raw as Map);
                    loading = false;
                  });
                } catch (error) {
                  if (dialogContext.mounted) refresh(() => loading = false);
                  _message('تعذر التحقق من الرمز: $error');
                }
              },
              child: const Text('تحقق'),
            ),
          ],
        ),
      ),
    );
    code.dispose();
  }

  Widget _certificatesPage() {
    final certificatesFuture = _loadMyCertificates();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle(t('شهاداتي', 'My certificates')),
        const SizedBox(height: 8),
        Text(t('تصدر الشهادة بعد إكمال جميع دروس الدورة واجتياز جميع اختباراتِها.', 
          'Certificates are issued after completing every lesson and passing every course quiz.'),
          style: const TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 12),
        Align(alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: _verifyCertificateDialog,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('التحقق من شهادة'),
          )),
        const SizedBox(height: 18),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: certificatesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return const Text('تعذر تحميل شهاداتك حالياً. حاول تحديث الصفحة.');
            }
            final certificates = snapshot.data ?? [];
            if (certificates.isEmpty) {
              return Card(elevation: 0, color: Colors.white,
                child: Padding(padding: const EdgeInsets.all(22), child: Column(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 48, color: purple),
                    const SizedBox(height: 10),
                    const Text('لا توجد شهادات صادرة حتى الآن.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('أكمل دورة تعليمية ثم اطلب إصدار الشهادة من الأسفل.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
                  ],
                )));
            }
            return Column(children: certificates.map((certificate) {
              final date = DateTime.tryParse(certificate['issued_at']?.toString() ?? '');
              final code = certificate['certificate_code']?.toString() ?? '';
              return Card(elevation: 0, color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE8E7FF),
                    child: Icon(Icons.workspace_premium, color: purple)),
                  title: Text(certificate['course_title']?.toString() ?? 'دورة تعليمية',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('الرمز: $code\nالإصدار: ${date?.toLocal().toString().substring(0, 10) ?? '—'}'),
                  isThreeLine: true,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: 'طباعة الشهادة أو حفظها PDF',
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: () => _printCertificate(certificate),
                    ),
                    IconButton(
                      tooltip: 'نسخ رمز الشهادة',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        _message('تم نسخ رمز الشهادة.');
                      },
                    ),
                  ]),
                ));
            }).toList());
          },
        ),
        const Divider(height: 32),
        _sectionTitle(t('الدورات المؤهلة للإصدار', 'Courses to certify')),
        const SizedBox(height: 8),
        const Text('يمكنك طلب الشهادة من هنا؛ تتحقق قاعدة البيانات من إكمال الدروس واجتياز الاختبارات قبل إصدارها.',
          style: TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 12),
        FutureBuilder<List<Course>>(
          future: learningCoursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return const Text('تعذر تحميل الدورات المسجل بها.');
            final enrolled = (snapshot.data ?? [])
              .where((course) => course.status == 'published').toList();
            if (enrolled.isEmpty) return const Text('لا توجد دورات منشورة مسجل بها حالياً.');
            return Column(children: enrolled.map((course) => Card(
              elevation: 0, color: Colors.white,
              child: ListTile(
                title: Text(course.title),
                subtitle: Text('تقدم الدروس: ${(course.progress * 100).round()}%'),
                trailing: FilledButton.tonal(
                  onPressed: () => _issueCertificate(course),
                  child: const Text('طلب الشهادة'),
                ),
              ),
            )).toList());
          },
        ),
      ],
    );
  }

  Widget _profilePage() {
    final user = supabase.auth.currentUser;
    final metadataName = user?.userMetadata?['display_name'] as String?;
    final displayName = metadataName?.trim().isNotEmpty == true
        ? metadataName!.trim()
        : (user?.email ?? t('مستخدم الأكاديمية', 'Academy user'));
    final roleLabel = widget.role == 'admin'
        ? t('حساب مدير', 'Administrator account')
        : widget.role == 'teacher'
            ? t('حساب مدرّس', 'Teacher account')
            : t('حساب طالب', 'Student account');
    return ListView(padding: const EdgeInsets.all(24), children: [
    _sectionTitle(t('الملف الشخصي', 'Profile')),
    const SizedBox(height: 20),
    const CircleAvatar(radius: 38, backgroundColor: Color(0xFFE8E7FF), child: Icon(Icons.person, color: purple, size: 40)),
    const SizedBox(height: 12),
    Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    Text(user?.email ?? '', style: const TextStyle(color: Colors.blueGrey)),
    const SizedBox(height: 24),
    ListTile(leading: const Icon(Icons.verified_user_outlined), title: Text(roleLabel)),
    ListTile(
      leading: const Icon(Icons.edit_outlined),
      title: const Text('تعديل الاسم الظاهر'),
      trailing: const Icon(Icons.chevron_left),
      onTap: _editDisplayName,
    ),
    if (!widget.isTeacher)
      ListTile(
        leading: const Icon(Icons.history_edu_outlined),
        title: const Text('سجل نتائج اختباراتي'),
        subtitle: const Text('عرض المحاولات والدرجات السابقة'),
        trailing: const Icon(Icons.chevron_left),
        onTap: _showMyQuizHistory,
      ),
    ListTile(leading: const Icon(Icons.logout), title: Text(t('تسجيل الخروج', 'Sign out')),
      onTap: () async { await supabase.auth.signOut(); }),
    SwitchListTile(title: Text(t('English interface', 'الواجهة العربية')), value: english,
      onChanged: (v) => setState(() => english = v)),
  ]);
  }

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
    Future<List<Map<String, dynamic>>> quizzesFuture = supabase.from('quizzes')
      .select('id,title,passing_score,max_attempts').eq('course_id', course.id!).order('created_at');

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
                      OutlinedButton.icon(
                        onPressed: () => _editCourse(course),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('تعديل الدورة'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showCourseStudents(course.id!, course.title),
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('الطلاب والتقدم'),
                      ),
                      if (course.status != 'published')
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _publishCourse(course);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.publish), label: const Text('نشر الدورة'),
                        ),
                      if (course.status != 'archived')
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _archiveCourse(course);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.archive_outlined),
                          label: const Text('أرشفة الدورة'),
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
                                  dashboardStatsFuture = _loadDashboardStats();
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
                  Row(children: [
                    const Expanded(child: Text('اختبارات الدورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    if (widget.isTeacher)
                      TextButton.icon(
                        onPressed: () async {
                          await _createQuiz(initialCourseId: course.id);
                          refreshSheet(() {
                            quizzesFuture = supabase.from('quizzes').select('id,title,passing_score,max_attempts')
                              .eq('course_id', course.id!).order('created_at');
                          });
                        },
                        icon: const Icon(Icons.add), label: const Text('إنشاء اختبار'),
                      ),
                  ]),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: quizzesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                      if (snapshot.hasError) return const Text('تعذر تحميل الاختبارات.');
                      final quizzes = snapshot.data ?? [];
                      if (quizzes.isEmpty) return const Text('لا توجد اختبارات لهذه الدورة بعد.');
                      return Column(children: quizzes.map((quiz) => Card(
                        elevation: 0, color: const Color(0xFFF7F7FC),
                        child: ListTile(
                          leading: const Icon(Icons.quiz_outlined, color: purple),
                          title: Text(quiz['title'] as String? ?? 'اختبار'),
                          subtitle: Text(
                            widget.isTeacher
                              ? 'إدارة الأسئلة'
                              : 'درجة النجاح: ${quiz['passing_score'] ?? 50}%'
                                '${quiz['max_attempts'] == null ? '' : ' • الحد: ${quiz['max_attempts']} محاولات'}',
                          ),
                          trailing: widget.isTeacher
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.settings_outlined),
                                  tooltip: 'إعدادات الاختبار',
                                  onPressed: () async {
                                    await _editQuizSettings(quiz);
                                    refreshSheet(() {
                                      quizzesFuture = supabase.from('quizzes')
                                        .select('id,title,passing_score,max_attempts').eq('course_id', course.id!)
                                        .order('created_at');
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note_outlined),
                                  tooltip: 'إدارة أسئلة الاختبار',
                                  onPressed: () => _manageQuizQuestions(
                                    quiz['id'] as String,
                                    quiz['title'] as String? ?? 'اختبار',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.bar_chart_outlined),
                                  tooltip: 'عرض نتائج الطلاب',
                                  onPressed: () => _showQuizResults(quiz['id'] as String, quiz['title'] as String? ?? 'اختبار'),
                                ),
                                IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'إضافة سؤال',
                                  onPressed: () async {
                                    await _addQuizQuestion(quiz['id'] as String);
                                    refreshSheet(() {
                                      quizzesFuture = supabase.from('quizzes').select('id,title,passing_score,max_attempts')
                                        .eq('course_id', course.id!).order('created_at');
                                    });
                                  }),
                              ])
                            : const Icon(Icons.chevron_left),
                          onTap: widget.isTeacher ? null : () => _openQuiz(quiz['id'] as String),
                        ),
                      )).toList());
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
                          trailing: widget.isTeacher
                            ? PopupMenuButton<String>(
                                tooltip: 'إجراءات الدرس',
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    await _editLesson(lesson);
                                  } else if (value == 'up' || value == 'down') {
                                    await _moveLesson(
                                      course.id!,
                                      lesson['id'] as String,
                                      value == 'up' ? -1 : 1,
                                    );
                                  } else if (value == 'delete') {
                                    await _deleteLesson(lesson);
                                  }
                                  if (sheetContext.mounted) {
                                    refreshSheet(() {
                                      lessonsFuture = supabase.from('lessons')
                                        .select('id,title,description,video_path,is_preview,position')
                                        .eq('course_id', course.id!).order('position');
                                    });
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('تعديل الدرس')),
                                  PopupMenuItem(value: 'up', child: Text('تحريك للأعلى')),
                                  PopupMenuItem(value: 'down', child: Text('تحريك للأسفل')),
                                  PopupMenuItem(value: 'delete', child: Text('حذف الدرس')),
                                ],
                              )
                            : const Icon(Icons.chevron_left),
                          onTap: () async {
                            final path = lesson['video_path'] as String?;
                            if (path == null || path.isEmpty) {
                              _message('هذا الدرس لا يحتوي على فيديو بعد.');
                              return;
                            }
                            try {
                              final canTrackProgress = !widget.isTeacher && await enrollmentFuture;
                              final url = await supabase.storage.from('course-videos')
                                .createSignedUrl(path, 3600);
                              if (!context.mounted) return;
                              final navigator = Navigator.of(sheetContext);
                              navigator.pop();
                              await navigator.push(MaterialPageRoute(
                                builder: (_) => LessonPlayerScreen(
                                  title: lesson['title'] as String? ?? 'مشغل الدرس',
                                  videoUrl: url,
                                  lessonId: lesson['id'] as String,
                                  allowProgress: canTrackProgress,
                                ),
                              ));
                              if (mounted && canTrackProgress) {
                                setState(() {
                                  learningCoursesFuture = _loadLearningCourses();
                                  dashboardStatsFuture = _loadDashboardStats();
                                });
                              }
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

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink));

  Future<Map<String, int>> _loadDashboardStats() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {'courses': 0, 'completed': 0, 'enrolled': 0};
    final enrollments = await supabase.from('enrollments')
        .select('id,course_id').eq('student_id', user.id);
    final progress = await supabase.from('lesson_progress')
        .select('id').eq('student_id', user.id).eq('completed', true);
    final publishedCount = remoteCourses.where((course) => course.status == 'published').length;
    return {
      'courses': publishedCount,
      'completed': (progress as List).length,
      'enrolled': (enrollments as List).length,
    };
  }

  Widget _statRow() => FutureBuilder<Map<String, int>>(
    future: dashboardStatsFuture,
    builder: (context, snapshot) {
      final stats = snapshot.data ?? const <String, int>{};
      final loading = snapshot.connectionState == ConnectionState.waiting;
      final value = (String key) => loading ? '…' : '${stats[key] ?? 0}';
      return Wrap(spacing: 12, runSpacing: 12, children: [
        _stat(Icons.menu_book, value('courses'), t('دورات منشورة', 'Published courses')),
        _stat(Icons.check_circle_outline, value('completed'), t('دروس مكتملة', 'Completed lessons')),
        _stat(Icons.school_outlined, value('enrolled'), t('دورات التحقت بها', 'Enrolled courses')),
      ]);
    },
  );

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
