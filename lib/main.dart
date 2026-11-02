import 'package:flutter/material.dart';

void main() => runApp(const WebDesignAcademy());

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
      home: const AcademyHome(),
    );
  }
}

class Course {
  final String title, category, description, duration, level;
  final IconData icon;
  final Color color;
  final double progress;
  const Course(this.title, this.category, this.description, this.duration, this.level,
      this.icon, this.color, this.progress);
}

const courses = [
  Course('أساسيات تصميم الويب', 'البداية الصحيحة', 'تعرّف إلى الويب، المتصفحات، وبنية صفحات المواقع.', '6 دروس', 'مبتدئ', Icons.language, Color(0xFF6C63FF), .72),
  Course('HTML من الصفر', 'تطوير الواجهات', 'أنشئ هيكل صفحاتك باستخدام عناصر HTML الدلالية.', '12 درساً', 'مبتدئ', Icons.code, Color(0xFFFF8A65), .35),
  Course('CSS والتصميم المرئي', 'التنسيق والإبداع', 'أتقن الألوان والخطوط والتخطيطات والتصميم المتجاوب.', '15 درساً', 'مبتدئ', Icons.palette_outlined, Color(0xFF18A999), .12),
  Course('JavaScript التفاعلية', 'برمجة الويب', 'أضف التفاعل والحركة والمنطق إلى صفحات الويب.', '18 درساً', 'متوسط', Icons.bolt, Color(0xFFF2B544), 0),
];

class AcademyHome extends StatefulWidget {
  const AcademyHome({super.key});
  @override
  State<AcademyHome> createState() => _AcademyHomeState();
}

class _AcademyHomeState extends State<AcademyHome> {
  int selected = 0;
  bool isTeacher = false;
  bool english = false;
  String query = '';

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
                child: Icon(isTeacher ? Icons.cast_for_education : Icons.person, color: purple))),
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
      OutlinedButton.icon(onPressed: () => setState(() => isTeacher = !isTeacher),
        icon: Icon(isTeacher ? Icons.school : Icons.cast_for_education),
        label: Text(isTeacher ? t('عرض الطالب', 'Student view') : t('وضع المدرس', 'Teacher mode'))),
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
    if (!isTeacher) _hero(),
    if (isTeacher) _teacherPanel(),
    const SizedBox(height: 26),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(t('دورات مقترحة لك', 'Recommended courses'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink)),
      TextButton(onPressed: () => setState(() => selected = 1), child: Text(t('عرض الكل', 'View all'))),
    ]),
    const SizedBox(height: 12),
    LayoutBuilder(builder: (context, c) {
      final count = c.maxWidth > 1050 ? 4 : c.maxWidth > 650 ? 2 : 1;
      return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: courses.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 220),
        itemBuilder: (_, i) => _courseCard(courses[i], i));
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
    onPressed: () => _message(t('ستتوفر إدارة المحتوى بعد ربط قاعدة البيانات.', 'Content management will be enabled after database setup.')),
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
    ...courses.asMap().entries.where((e) => e.value.title.contains(query) || e.value.category.contains(query))
      .map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _courseCard(e.value, e.key))),
  ]);

  Widget _learningPage() => ListView(padding: const EdgeInsets.all(24), children: [
    _sectionTitle(t('متابعة التعلم', 'Continue learning')),
    const SizedBox(height: 8),
    Text(t('تابع من حيث توقفت.', 'Pick up where you left off.'), style: const TextStyle(color: Colors.blueGrey)),
    const SizedBox(height: 18),
    ...courses.where((c) => c.progress > 0).map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _courseCard(c, courses.indexOf(c)))),
    const SizedBox(height: 14),
    _sectionTitle(t('الدروس الأخيرة', 'Recent lessons')),
    _lessonTile('مقدمة إلى عالم الويب', 'أساسيات تصميم الويب', Icons.play_circle_fill),
    _lessonTile('بنية مستند HTML', 'HTML من الصفر', Icons.play_circle_fill),
  ]);

  Widget _profilePage() => ListView(padding: const EdgeInsets.all(24), children: [
    _sectionTitle(t('الملف الشخصي', 'Profile')),
    const SizedBox(height: 20),
    const CircleAvatar(radius: 38, backgroundColor: Color(0xFFE8E7FF), child: Icon(Icons.person, color: purple, size: 40)),
    const SizedBox(height: 12),
    Text(t('متعلم جديد', 'New learner'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    Text(t('عضو في أكاديمية تصميم الويب', 'Web Design Academy member'), style: const TextStyle(color: Colors.blueGrey)),
    const SizedBox(height: 24),
    SwitchListTile(title: Text(t('الدخول بوضع المدرّس', 'Teacher mode')), value: isTeacher,
      onChanged: (v) => setState(() => isTeacher = v)),
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

  void _openCourse(Course course) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Directionality(textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: Padding(padding: const EdgeInsets.all(24), child: SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(course.icon, color: course.color, size: 30), const SizedBox(width: 12),
            Expanded(child: Text(course.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 12),
          Text(course.description),
          const SizedBox(height: 18),
          _lessonTile('مقدمة الدورة والأهداف', course.title, Icons.play_circle_fill),
          _lessonTile('المفاهيم الأساسية', course.title, Icons.play_circle_fill),
          _lessonTile('تطبيق عملي', course.title, Icons.assignment_outlined),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () { Navigator.pop(context); _message(t('سيتم فتح مشغل الدروس عند ربط المحتوى.', 'Lesson player will be available when content is connected.')); },
            icon: const Icon(Icons.play_arrow), label: Text(t('ابدأ التعلم', 'Start learning')))),
        ])))),
  );

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
