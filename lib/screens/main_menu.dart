import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../l10n.dart';
import 'profile.dart';
import 'setting.dart';
import 'PlayingFieldScreen.dart';
import 'rating.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _State();
}

class _State extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  static const Color kBurgundy = Color(0xFF6B1F2B);
  

  late AnimationController _floatCtrl;
  late AnimationController _pressStart;
  late AnimationController _pressRating;

  @override
  void initState() {
    super.initState();

    AppLocale().addListener(() {
      if (mounted) setState(() {});
    });

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pressStart = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.05,
    );

    _pressRating = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pressStart.dispose();
    _pressRating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ФОН
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/main_window.JPEG',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1a0a05)),
            ),
          ),

          // ДЕКОРА
          ..._floatingDecorations(size),

          // ЛОГО
          Positioned(
            left: 0,
            right: 0,
            top: 250,
            child: AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, __) {
                final breath =
                    1.0 + 0.03 * math.sin(_floatCtrl.value * math.pi * 2);

                return Transform.scale(
                  scale: breath,
                  child: const Center(
                    child: Text(
                      'MAHJONG',
                      style: TextStyle(
                        fontSize: 44,
                        fontFamily: 'Aboreto',
                        color: kBurgundy,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Color(0x55000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // START
          Positioned(
            left: 17,
            right: 17,
            top: 400,
            child: _bigButton(
              label: tr('НАЧАТЬ', 'START'),
              onTap: () {
                _pressStart.forward().then((_) => _pressStart.reverse());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlayingFieldScreen(),
                  ),
                );
              },
              ctrl: _pressStart,
              fontSize: 36,
              height: 64,
            ),
          ),

          // RATING
          Positioned(
            left: 50,
            right: 50,
            top: 650,
            child: _bigButton(
              label: tr('РЕЙТИНГ', 'RATING'),
              onTap: () {
                _pressRating.forward().then((_) => _pressRating.reverse());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RatingScreen(),
                  ),
                );
              },
              ctrl: _pressRating,
              fontSize: 30,
              height: 52,
            ),
          ),

          // PROFILE
          Positioned(
            left: 17,
            top: 43,
            child: AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, __) {
                final rot =
                    0.05 * math.sin(_floatCtrl.value * math.pi * 2);

                return Transform.rotate(
                  angle: rot,
                  child: _iconButton(
                    'assets/images/backgrounds/profile.JPEG',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // SETTINGS
          Positioned(
            right: 17,
            top: 44,
            child: AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, __) {
                return Transform.rotate(
                  angle: _floatCtrl.value * 0.3,
                  child: _iconButton(
                    'assets/images/backgrounds/setting.PNG',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingScreen(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigButton({
    required String label,
    required VoidCallback onTap,
    required AnimationController ctrl,
    required double fontSize,
    required double height,
  }) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) => ctrl.reverse(),
      onTapCancel: () => ctrl.reverse(),
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final pressed = ctrl.value;

          return Transform.translate(
            offset: Offset(0, pressed * 60),

            child: Container(
              height: height,
              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: kBurgundy.withOpacity(0.60),

                borderRadius: BorderRadius.circular(30),

                boxShadow: [
                  // мягкая тень как у иконок
                  const BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),

                  // лёгкое свечение
                  BoxShadow(
                    color: kBurgundy.withOpacity(0.15),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),

              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  letterSpacing: 3.0,
                  fontFamily: 'Forum',
                  fontWeight: FontWeight.w400,
                  shadows: const [
                    Shadow(
                      color: Color(0xAA000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _iconButton(String asset, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.cover,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x44000000),
            ),
          ),
        ),
      );

  List<Widget> _floatingDecorations(Size size) {
    final symbols = ['麻', '將', '中', '發', '東', '南', '西', '北'];

    return List.generate(8, (i) {
      return AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, __) {
          final t = (_floatCtrl.value + i * 0.13) % 1.0;
          final startX = (i * 67) % size.width;

          final dx = startX + math.sin(t * math.pi * 2 + i) * 20;
          final dy = size.height * t - 80;

          return Positioned(
            left: dx,
            top: dy,
            child: Opacity(
              opacity: 0.08,
              child: Text(
                symbols[i],
                style: const TextStyle(
                  fontSize: 50,
                  color: kBurgundy,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
