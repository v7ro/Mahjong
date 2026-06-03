import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_menu.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _State();
}

class _State extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  static const kBurgundy = Color(0xFF6B1F2B);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.addListener(() { if (mounted) setState(() {}); });
    _ctrl.forward().whenComplete(_navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const MainMenuScreen()));
    } else {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(children: [
      Positioned.fill(child: Image.asset(
        'assets/images/backgrounds/loading.jpeg', fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1a0a05)))),
      Positioned(left: 0, right: 0, bottom: 100,
        child: const Center(child: Text('MAHJONG', style: TextStyle(
          fontSize: 22, fontFamily: 'Aboreto',
          color: kBurgundy, letterSpacing: 3)))),
      Positioned(left: 32, right: 32, bottom: 72,
        child: ClipRRect(borderRadius: BorderRadius.circular(5),
          child: SizedBox(height: 8, child: LinearProgressIndicator(
            value: _anim.value,
            backgroundColor: const Color(0xFFE6D7C8),
            valueColor: const AlwaysStoppedAnimation(kBurgundy))))),
    ]));
}