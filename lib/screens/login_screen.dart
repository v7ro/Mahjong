import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'main_menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  static const Color kBurgundy = Color(0xFF6B1F2B);
  final _fs = FirebaseService();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  bool _isRegister = false, _loading = false;
  String? _error;

  @override void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); _nameCtrl.dispose(); super.dispose(); }

  void _go() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainMenuScreen()));

  Future<void> _emailAuth() async {
    final e = _emailCtrl.text.trim(), p = _passCtrl.text.trim(), n = _nameCtrl.text.trim();
    if (e.isEmpty || p.isEmpty) { setState(() => _error = 'Заполните все поля'); return; }
    if (_isRegister && n.isEmpty) { setState(() => _error = 'Введите имя'); return; }
    setState(() { _loading = true; _error = null; });
    final err = _isRegister ? await _fs.registerWithEmail(e, p, n) : await _fs.signInWithEmail(e, p);
    if (!mounted) return;
    if (err != null) setState(() { _error = err; _loading = false; });
    else _go();
  }

  Future<void> _google() async {
    setState(() { _loading = true; _error = null; });
    final r = await _fs.signInWithGoogle();
    if (!mounted) return;
    if (r == null) setState(() { _error = 'Вход через Google отменён'; _loading = false; });
    else _go();
  }

  Future<void> _apple() async {
    setState(() { _loading = true; _error = null; });
    final r = await _fs.signInWithApple();
    if (!mounted) return;
    if (r == null) setState(() { _error = 'Вход через Apple отменён'; _loading = false; });
    else _go();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/backgrounds/loading.jpeg', fit: BoxFit.cover,
          errorBuilder: (_,__,___) => Container(color: const Color(0xFF1a0a05)))),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('麻將', style: TextStyle(fontSize: 72, color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 16)])),
            const SizedBox(height: 4),
            Text(_isRegister ? 'регистрация' : 'вход',
              style: const TextStyle(fontSize: 20, color: Colors.white70, fontFamily: 'Aboreto', letterSpacing: 3)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.93),
                borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                if (_isRegister) ...[_field(_nameCtrl, 'Имя', Icons.person), const SizedBox(height: 12)],
                _field(_emailCtrl, 'Email', Icons.email, type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field(_passCtrl, 'Пароль', Icons.lock, obscure: true),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _loading ? null : _emailAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBurgundy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isRegister ? 'зарегистрироваться' : 'войти',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Aboreto')),
                )),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
                  child: Text(_isRegister ? 'уже есть аккаунт? войти' : 'нет аккаунта? регистрация',
                    style: const TextStyle(color: kBurgundy, fontSize: 13))),
                const Divider(height: 24),
                _socialBtn(onTap: _loading ? null : _google,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.network('https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      width: 20, height: 20, errorBuilder: (_,__,___) => const Icon(Icons.g_mobiledata, size: 20)),
                    const SizedBox(width: 10),
                    const Text('войти через Google', style: TextStyle(color: Colors.black87, fontSize: 14)),
                  ]),
                  color: Colors.white, border: Colors.grey.shade300),
                if (Platform.isIOS || Platform.isMacOS) ...[
                  const SizedBox(height: 10),
                  _socialBtn(onTap: _loading ? null : _apple,
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.apple, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('войти через Apple', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ]),
                    color: Colors.black, border: Colors.black),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading ? null : _go,
                  child: const Text('продолжить без входа', style: TextStyle(color: Colors.grey, fontSize: 12))),
              ]),
            ),
          ]),
        ))),
      ]),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon, {bool obscure=false, TextInputType? type}) =>
    TextField(controller: c, obscureText: obscure, keyboardType: type,
      decoration: InputDecoration(
        hintText: hint, prefixIcon: Icon(icon, color: kBurgundy),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBurgundy, width: 2)),
        filled: true, fillColor: Colors.grey.shade50));

  Widget _socialBtn({VoidCallback? onTap, required Widget child, required Color color, required Color border}) =>
    SizedBox(width: double.infinity, child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: color, side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: child));
}
