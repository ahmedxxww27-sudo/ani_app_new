import 'package0/flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showAuthDialog({required bool isSignUp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
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
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'البريد الإلكتروني',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
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
              onPressed: () async {
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  _showMsg('يرجى ملء كافة الحقول', isError: true);
                  return;
                }

                Navigator.pop(context);

                try {
                  if (isSignUp) {
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    _showMsg('تم إنشاء الحساب بنجاح!');
                  } else {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    _showMsg('تم تسجيل الدخول بنجاح!');
                  }
                } on FirebaseAuthException catch (e) {
                  _showMsg(e.message ?? 'حدث خطأ في العملية', isError: true);
                }
              },
              child: Text(
                isSignUp ? 'إنشاء الحساب' : 'دخول',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
          Container(color: Colors.black.withOpacity(0.45)),
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
                    onPressed: () => _showMsg('ميزة Apple تتطلب حساب مطور Apple مدفوع', isError: true),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () => _showAuthDialog(isSignUp: false),
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
                    onPressed: () => _showAuthDialog(isSignUp: true),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => _showMsg('أدخل بريدك في شاشة الدخول ثم تواصل معنا لتغييرها'),
                    child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Colors.white70)),
                  ),
                  const Spacer(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(children: [Icon(Icons.headset_mic_outlined, size: 18, color: Colors.white70), SizedBox(width: 5), Text('الدعم', style: TextStyle(color: Colors.white70))]),
                      Text('|', style: TextStyle(color: Colors.white30)),
                      Row(children: [Icon(Icons.language, size: 18, color: Colors.white70), SizedBox(width: 5), Text('اللغة', style: TextStyle(color: Colors.white70))]),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
