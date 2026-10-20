import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AniApp());
}

class AniApp extends StatelessWidget {
  const AniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anī App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ==================== 1. شاشة تسجيل الدخول ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  void _showAuthModal({required bool isSignUp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 25,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSignUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'البريد الإلكتروني',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'كلمة المرور',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _navigateToMain();
              },
              child: Text(isSignUp ? 'إنشاء حساب والدخول' : 'دخول', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1507525428034-b723cf961d3e'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  const Spacer(),
                  const Text('آني', style: TextStyle(fontSize: 65, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('Anī', style: TextStyle(fontSize: 22, color: Colors.white70, letterSpacing: 3)),
                  const SizedBox(height: 10),
                  const Text('تواصل . شارك . كن أنت', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('تسجيل الدخول باستخدام Apple', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    onPressed: _navigateToMain,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () => _showAuthModal(isSignUp: false),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('تسجيل الدخول', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white30)),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('أو', style: TextStyle(color: Colors.white60))),
                      Expanded(child: Divider(color: Colors.white30)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('إنشاء حساب جديد', style: TextStyle(fontSize: 16)),
                    onPressed: () => _showAuthModal(isSignUp: true),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 2. شاشة التنقل الرئيسية كاملة ====================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    AddPostScreen(),
    ReelsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'البحث'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'إضافة'),
          BottomNavigationBarItem(icon: Icon(Icons.movie_outlined), label: 'الريلز'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

// ==================== 3. الواجهات المختلفة ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('آني - الصفحة الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            color: const Color(0xFF121212),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Text('A')),
                  title: Text('مستخدم آني', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('قبل ساعة واحدة', style: TextStyle(color: Colors.grey)),
                ),
                Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[900],
                  child: const Icon(Icons.image, size: 80, color: Colors.white24),
                ),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('منشور تجريبي داخل تطبيق آني الجديد!', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'البحث في آني...',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
      ),
      body: const Center(child: Text('صفحة الاستكشاف والبحت', style: TextStyle(color: Colors.white54, fontSize: 18))),
    );
  }
}

class AddPostScreen extends StatelessWidget {
  const AddPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منشور جديد'), backgroundColor: Colors.black),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.white54),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {},
              child: const Text('اختيار صورة أو فيديو'),
            )
          ],
        ),
      ),
    );
  }
}

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey[900], child: const Center(child: Icon(Icons.play_circle_fill, size: 100, color: Colors.white30))),
          const Positioned(
            bottom: 20,
            left: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@ani_user', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 5),
                Text('فيديو ريلز قصير تجريبي 🎬', style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي'), backgroundColor: Colors.black),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(radius: 45, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(height: 10),
          const Text('مستخدم آني الحقيقي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
