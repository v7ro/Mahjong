import 'package:flutter/material.dart';
import 'main_menu.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _animation;

  static const Color burgundy = Color(0xFF6B1F2B);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    _controller.forward().whenComplete(() {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainMenuScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

/// ФОН
          Positioned.fill(
            child: Image.asset(
              'assets/images/loading.jpg',
              fit: BoxFit.cover,
            ),
          ),

/// LOADING
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: Center(
              child: Text(
                'LOADING',
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'Aboreto',
                  color: burgundy,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

/// ПРОГРЕСС-БАР
          Positioned(
            left: 30,
            right: 30,
            bottom: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: LinearProgressIndicator(
                  value: _animation.value,
                  backgroundColor: const Color(0xFFE6D7C8),
                  valueColor: const AlwaysStoppedAnimation(burgundy),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
