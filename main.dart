import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Configure native Firebase files first.
  runApp(const AniApp());
}

final auth = FirebaseAuth.instance;
final db = FirebaseFirestore.instance;
final storage = FirebaseStorage.instance;

class AniApp extends StatelessWidget {
  const AniApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'آني | ANI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6D4AFF)),
      scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      ),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: auth.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.data == null) return const AuthPage();
      return const MainShell();
    },
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signup = false, _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose(); _username.dispose(); _email.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_signup) {
        final username = _username.text.trim().toLowerCase();
        final credential = await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text);
        final uid = credential.user!.uid;
        // Reserve username atomically so two users cannot claim the same handle.
        final handleRef = db.collection('usernames').doc(username);
        await db.runTransaction((tx) async {
          final existing = await tx.get(handleRef);
          if (existing.exists) throw Exception('اسم المستخدم محجوز، اختر اسماً آخر.');
          tx.set(handleRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
          tx.set(db.collection('users').doc(uid), {
            'uid': uid, 'displayName': _name.text.trim(),
            'username': username, 'email': _email.text.trim(),
            'bio': '', 'photoUrl': '', 'city': '', 'isPrivate': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
        await credential.user?.sendEmailVerification();
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authMessage(e.code));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authMessage(String code) => switch (code) {
    'email-already-in-use' => 'هذا البريد مستخدم بالفعل.',
    'invalid-email' => 'صيغة البريد الإلكتروني غير صحيحة.',
    'weak-password' => 'كلمة المرور ضعيفة؛ استخدم 6 أحرف على الأقل.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' => 'بيانات الدخول غير صحيحة.',
    'too-many-requests' => 'محاولات كثيرة. حاول لاحقاً.',
    'network-request-failed' => 'تعذر الاتصال بالإنترنت.',
    _ => 'تعذر إكمال العملية: $code',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460), child: Form(
          key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 76, width: 76, alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 42)),
              const SizedBox(height: 18),
              const Text('آني | ANI', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(_signup ? 'أنشئ حسابك وابدأ التواصل' : 'مساحتك للتواصل والمشاركة',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 28),
              if (_signup) ...[
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم الظاهر'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم الظاهر' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                  validator: (v) {
                    final x = (v ?? '').trim().toLowerCase();
                    if (!RegExp(r'^[a-z0-9_.]{1,30}$').hasMatch(x)) {
                      return 'استخدم أحرفاً إنجليزية أو أرقاماً أو _ أو . (حتى 30 حرفاً)';
                    }
                    return null;
                  }),
                const SizedBox(height: 12),
              ],
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                validator: (v) => (v == null || !v.contains('@')) ? 'أدخل بريداً صحيحاً' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _password, obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                validator: (v) => (v == null || v.length < 6) ? 'كلمة المرور 6 أحرف على الأقل' : null),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Padding(padding: const EdgeInsets.all(13),
                  child: _busy ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_signup ? 'إنشاء الحساب' : 'تسجيل الدخول')),
              ),
              TextButton(onPressed: _busy ? null : () => setState(() {
                _signup = !_signup; _error = null;
              }), child: Text(_signup ? 'لديك حساب؟ سجّل الدخول' : 'إنشاء حساب جديد')),
              if (!_signup)
                TextButton(onPressed: () async {
                  final email = _email.text.trim();
                  if (!email.contains('@')) {
                    setState(() => _error = 'أدخل بريدك الإلكتروني أولاً ثم اضغط استعادة كلمة المرور.');
                    return;
                  }
                  try {
                    await auth.sendPasswordResetEmail(email: email);
                    if (mounted) setState(() => _error = 'أرسلنا رابط استعادة كلمة المرور إلى بريدك إذا كان مسجلاً.');
                  } catch (_) {
                    if (mounted) setState(() => _error = 'تعذر إرسال رابط الاستعادة. تحقق من البريد والاتصال.');
                  }
                }, child: const Text('نسيت كلمة المرور؟')),
              const SizedBox(height: 10),
              const Text('التسجيل بالبريد الإلكتروني متاح بعد إعداد Firebase. تسجيل الهاتف يحتاج إعداد Phone Authentication واختبار SMS منفصل.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    ))),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _pages = const [FeedPage(), SearchPage(), CreatePostPage(), ProfilePage()];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('آني', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(tooltip: 'الرسائل', onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MessagesNoticePage())),
          icon: const Icon(Icons.chat_bubble_outline)),
        IconButton(tooltip: 'الإشعارات', onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NotificationsPage())),
          icon: const Icon(Icons.notifications_none)),
      ]),
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: NavigationBar(selectedIndex: _index, onDestinationSelected: (v) => setState(() => _index = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.search), label: 'بحث'),
        NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'نشر'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
      ]),
  );
}

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: db.collection('posts').orderBy('createdAt', descending: true).limit(30).snapshots(),
    builder: (context, snap) {
      if (snap.hasError) return const Center(child: Text('تعذر تحميل المنشورات. تحقق من إعدادات قاعدة البيانات.'));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final posts = snap.data!.docs;
      if (posts.isEmpty) return const EmptyState(icon: Icons.photo_library_outlined,
        title: 'أهلاً بك في آني', detail: 'لا توجد منشورات بعد. كن أول من يشارك شيئاً.');
      return ListView.builder(itemCount: posts.length, itemBuilder: (context, i) {
        final doc = posts[i]; final p = doc.data();
        return PostCard(id: doc.id, post: p);
      });
    },
  );
}

class PostCard extends StatelessWidget {
  final String id; final Map<String, dynamic> post;
  const PostCard({super.key, required this.id, required this.post});
  Future<void> _toggleLike() async {
    final uid = auth.currentUser!.uid;
    final ref = db.collection('posts').doc(id).collection('likes').doc(uid);
    final existing = await ref.get();
    if (existing.exists) { await ref.delete(); } else {
      await ref.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
    }
  }
  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser!.uid;
    final created = post['createdAt'] as Timestamp?;
    final date = created == null ? '' : DateFormat('yyyy/MM/dd • HH:mm').format(created.toDate());
    return Card(margin: const EdgeInsets.fromLTRB(12, 8, 12, 10), clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          leading: CircleAvatar(backgroundImage: (post['photoUrl'] ?? '').toString().isNotEmpty
            ? NetworkImage(post['photoUrl']) : null, child: (post['photoUrl'] ?? '').toString().isEmpty
            ? const Icon(Icons.person) : null),
          title: Text('@${post['username'] ?? 'user'}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(date),
          trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => showModalBottomSheet(
            context: context, builder: (_) => SafeArea(child: ListTile(
              leading: const Icon(Icons.flag_outlined), title: const Text('الإبلاغ عن المنشور'),
              onTap: () async {
                await db.collection('reports').add({'postId': id, 'reporterUid': uid,
                  'createdAt': FieldValue.serverTimestamp(), 'status': 'open'});
                if (context.mounted) Navigator.pop(context);
              })))),
        ),
        if ((post['mediaUrl'] ?? '').toString().isNotEmpty)
          AspectRatio(aspectRatio: 1, child: Image.network(post['mediaUrl'], fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 50)))),
        if ((post['caption'] ?? '').toString().isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(post['caption'])),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: db.collection('posts').doc(id).collection('likes').doc(uid).snapshots(),
          builder: (context, likeSnap) => Row(children: [
            IconButton(onPressed: _toggleLike, icon: Icon(
              likeSnap.data?.exists == true ? Icons.favorite : Icons.favorite_border,
              color: likeSnap.data?.exists == true ? Colors.pink : null)),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('posts').doc(id).collection('likes').snapshots(),
              builder: (_, s) => Text('${s.data?.docs.length ?? 0} إعجاب')),
            const Spacer(),
            TextButton.icon(onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => CommentsPage(postId: id))),
              icon: const Icon(Icons.mode_comment_outlined), label: const Text('التعليقات')),
            const SizedBox(width: 8),
          ]),
        ),
      ]),
    );
  }
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}
class _CreatePostPageState extends State<CreatePostPage> {
  final _caption = TextEditingController();
  XFile? _image; bool _busy = false; String? _message;
  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (picked != null) setState(() { _image = picked; _message = null; });
  }
  Future<void> _publish() async {
    if (_image == null) { setState(() => _message = 'اختر صورة قبل النشر.'); return; }
    setState(() { _busy = true; _message = null; });
    try {
      final user = auth.currentUser!;
      final userDoc = await db.collection('users').doc(user.uid).get();
      final profile = userDoc.data() ?? {};
      final postRef = db.collection('posts').doc();
      final path = 'posts/${user.uid}/${postRef.id}.jpg';
      final task = await storage.ref(path).putFile(File(_image!.path),
        SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();
      await postRef.set({
        'id': postRef.id, 'uid': user.uid, 'username': profile['username'] ?? '',
        'photoUrl': profile['photoUrl'] ?? '', 'mediaUrl': url, 'mediaPath': path,
        'mediaType': 'image', 'caption': _caption.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), 'visibility': 'public',
      });
      _caption.clear();
      if (mounted) setState(() { _image = null; _message = 'تم نشر المنشور بنجاح.'; });
    } catch (e) {
      if (mounted) setState(() => _message = 'فشل النشر: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() { _caption.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('إنشاء منشور', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    OutlinedButton.icon(onPressed: _busy ? null : _pick, icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text('اختيار صورة من الجهاز')),
    if (_image != null) ...[
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(16),
        child: Image.file(File(_image!.path), height: 280, fit: BoxFit.cover)),
    ],
    const SizedBox(height: 12),
    TextField(controller: _caption, maxLines: 5, maxLength: 2200,
      decoration: const InputDecoration(labelText: 'اكتب وصفاً للمنشور', alignLabelWithHint: true)),
    const SizedBox(height: 12),
    FilledButton(onPressed: _busy ? null : _publish,
      child: _busy ? const CircularProgressIndicator() : const Text('نشر الآن')),
    if (_message != null) Padding(padding: const EdgeInsets.all(8), child: Text(_message!)),
    const SizedBox(height: 12),
    const Text('هذه النسخة تنشر الصور. رفع الفيديو والقصص يحتاجان استكمال مسارات الوسائط والاختبار قبل الإنتاج.',
      style: TextStyle(color: Colors.grey, fontSize: 12)),
  ]);
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final user = snap.data!.data() ?? {};
        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            CircleAvatar(radius: 38, backgroundImage: (user['photoUrl'] ?? '').toString().isNotEmpty
              ? NetworkImage(user['photoUrl']) : null,
              child: (user['photoUrl'] ?? '').toString().isEmpty ? const Icon(Icons.person, size: 38) : null),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user['displayName'] ?? 'مستخدم آني', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('@${user['username'] ?? ''}'),
              if ((user['bio'] ?? '').toString().isNotEmpty) Text(user['bio']),
            ])),
          ]),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EditProfilePage())), child: const Text('تعديل الملف الشخصي')),
          OutlinedButton.icon(onPressed: () async {
            await auth.signOut();
          }, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
          const Divider(height: 28),
          const Text('منشوراتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('posts').where('uid', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots(),
            builder: (context, postsSnap) {
              if (postsSnap.hasError) return const Text('تعذر تحميل المنشورات.');
              if (!postsSnap.hasData) return const Center(child: CircularProgressIndicator());
              return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: postsSnap.data!.docs.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                itemBuilder: (_, i) => Image.network(postsSnap.data!.docs[i].data()['mediaUrl'],
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)));
            },
          ),
        ]);
      },
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}
class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController(), _bio = TextEditingController(), _city = TextEditingController();
  bool _private = false, _loaded = false, _busy = false;
  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser!.uid;
    return Scaffold(appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!.data() ?? {};
          if (!_loaded) {
            _name.text = d['displayName'] ?? ''; _bio.text = d['bio'] ?? '';
            _city.text = d['city'] ?? ''; _private = d['isPrivate'] == true; _loaded = true;
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم الظاهر')),
            const SizedBox(height: 12),
            TextField(controller: _bio, maxLength: 160, decoration: const InputDecoration(labelText: 'النبذة التعريفية')),
            const SizedBox(height: 12),
            TextField(controller: _city, decoration: const InputDecoration(labelText: 'المحافظة أو المدينة (اختياري)')),
            SwitchListTile(title: const Text('حساب خاص'), value: _private,
              onChanged: (v) => setState(() => _private = v)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _busy ? null : () async {
              setState(() => _busy = true);
              try {
                await db.collection('users').doc(uid).update({
                  'displayName': _name.text.trim(), 'bio': _bio.text.trim(),
                  'city': _city.text.trim(), 'isPrivate': _private,
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
              } finally { if (mounted) setState(() => _busy = false); }
            }, child: _busy ? const CircularProgressIndicator() : const Text('حفظ التعديلات')),
          ]);
        },
      ));
  }
  @override
  void dispose() { _name.dispose(); _bio.dispose(); _city.dispose(); super.dispose(); }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController(); String _q = '';
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _query,
      decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'ابحث باسم المستخدم',
        suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => setState(() => _q = _query.text.trim().toLowerCase())),
      ), onSubmitted: (v) => setState(() => _q = v.trim().toLowerCase()))),
    Expanded(child: _q.isEmpty ? const EmptyState(icon: Icons.search, title: 'ابحث عن أشخاص', detail: 'اكتب اسم المستخدم ثم اضغط بحث.')
      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').orderBy('username').startAt([_q]).endAt(['$_q\uf8ff']).limit(25).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('تعذر البحث. تحقق من فهارس Firestore وقواعد الأمان.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.where((d) => d.id != auth.currentUser!.uid).toList();
          if (docs.isEmpty) return const Center(child: Text('لا توجد نتائج.'));
          return ListView(children: docs.map((d) {
            final u = d.data();
            return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(u['displayName'] ?? ''), subtitle: Text('@${u['username'] ?? ''}'),
              trailing: IconButton(icon: const Icon(Icons.person_add_alt_1), onPressed: () async {
                await db.collection('users').doc(auth.currentUser!.uid).collection('following').doc(d.id)
                  .set({'uid': d.id, 'createdAt': FieldValue.serverTimestamp()});
                await db.collection('users').doc(d.id).collection('followers').doc(auth.currentUser!.uid)
                  .set({'uid': auth.currentUser!.uid, 'createdAt': FieldValue.serverTimestamp()});
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت المتابعة')));
              }));
          }).toList());
        },
      )),
  ]);
  @override
  void dispose() { _query.dispose(); super.dispose(); }
}

class CommentsPage extends StatefulWidget {
  final String postId;
  const CommentsPage({super.key, required this.postId});
  @override
  State<CommentsPage> createState() => _CommentsPageState();
}
class _CommentsPageState extends State<CommentsPage> {
  final _text = TextEditingController(); bool _busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('التعليقات')),
    body: Column(children: [
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('posts').doc(widget.postId).collection('comments').orderBy('createdAt').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('تعذر تحميل التعليقات.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const EmptyState(icon: Icons.mode_comment_outlined, title: 'لا توجد تعليقات', detail: 'ابدأ الحوار باحترام.');
          return ListView(children: snap.data!.docs.map((d) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(d.data()['username'] ?? 'مستخدم'),
            subtitle: Text(d.data()['text'] ?? ''),
            trailing: d.data()['uid'] == auth.currentUser!.uid ? IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: () => d.reference.delete()) : null,
          )).toList());
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        Expanded(child: TextField(controller: _text, decoration: const InputDecoration(hintText: 'اكتب تعليقاً...'))),
        IconButton(onPressed: _busy ? null : () async {
          final text = _text.text.trim(); if (text.isEmpty) return;
          setState(() => _busy = true);
          try {
            final u = await db.collection('users').doc(auth.currentUser!.uid).get();
            await db.collection('posts').doc(widget.postId).collection('comments').add({
              'uid': auth.currentUser!.uid, 'username': u.data()?['username'] ?? '',
              'text': text, 'createdAt': FieldValue.serverTimestamp(),
            });
            _text.clear();
          } catch (_) {}
          if (mounted) setState(() => _busy = false);
        }, icon: const Icon(Icons.send)),
      ]))),
    ]));
  @override
  void dispose() { _text.dispose(); super.dispose(); }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser!.uid;
    return Scaffold(appBar: AppBar(title: const Text('الإشعارات')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').doc(uid).collection('notifications').orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('تعذر تحميل الإشعارات.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const EmptyState(icon: Icons.notifications_none, title: 'لا توجد إشعارات', detail: 'ستظهر هنا الإشعارات عندما تتوفر.');
          return ListView(children: snap.data!.docs.map((d) => ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(d.data()['title'] ?? 'إشعار'),
            subtitle: Text(d.data()['body'] ?? ''),
            onTap: () => d.reference.update({'read': true}),
          )).toList());
        },
      ));
  }
}

class MessagesNoticePage extends StatelessWidget {
  const MessagesNoticePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('الرسائل')),
    body: const EmptyState(icon: Icons.chat_bubble_outline, title: 'الرسائل الخاصة',
      detail: 'واجهة الرسائل موجودة ضمن خطة المشروع، لكن المحادثات الفعلية تحتاج تنفيذ خدمة المحادثات وقواعد صلاحياتها قبل إطلاق الإنتاج.'));
}

class EmptyState extends StatelessWidget {
  final IconData icon; final String title, detail;
  const EmptyState({super.key, required this.icon, required this.title, required this.detail});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 48, color: Colors.deepPurple),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(detail, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
    ])));
}
