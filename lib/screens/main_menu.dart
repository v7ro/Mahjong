import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../l10n.dart';
import 'profile.dart';
import 'setting.dart';
import 'PlayingFieldScreen.dart';
import 'rating.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override State<MainMenuScreen> createState() => _State();
}

class _State extends State<MainMenuScreen> with TickerProviderStateMixin {
  static const kBurgundy = Color(0xFF6B1F2B);
  static const kGold = Color(0xFFD4AF37);

  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _pressStart;
  late AnimationController _pressRating;

  @override
  void initState() {
    super.initState();
    AppLocale().addListener(() { if (mounted) setState(() {}); });
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pressStart  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0, upperBound: 1);
    _pressRating = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0, upperBound: 1);
  }

  @override
  void dispose() {
    _floatCtrl.dispose(); _glowCtrl.dispose();
    _pressStart.dispose(); _pressRating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        // Фон
        Positioned.fill(child: Image.asset(
          'assets/images/backgrounds/main_window.jpeg', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1a0a05)))),

        // Тонкий тёмный оверлей для читаемости
        Positioned.fill(child: Container(color: const Color(0x22000000))),

        // Плавающие иероглифы
        ..._floatingSymbols(size),

        // Сияние вокруг MAHJONG
        Positioned(left: 0, right: 0, top: size.height * 0.28,
          child: AnimatedBuilder(animation: _glowCtrl, builder: (_, __) {
            return Center(child: Container(
              width: 280, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(
                  color: kBurgundy.withOpacity(0.15 + _glowCtrl.value * 0.15),
                  blurRadius: 40, spreadRadius: 10)]),
            ));
          })),

        // MAHJONG надпись
        Positioned(left: 0, right: 0, top: size.height * 0.29,
          child: AnimatedBuilder(animation: _floatCtrl, builder: (_, __) {
            final breath = 1.0 + 0.015 * math.sin(_floatCtrl.value * math.pi * 2);
            return Transform.scale(scale: breath,
              child: const Center(child: Text('MAHJONG',
                style: TextStyle(
                  fontSize: 48, fontFamily: 'Aboreto', color: kBurgundy,
                  letterSpacing: 6,
                  shadows: [
                    Shadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 4)),
                    Shadow(color: Color(0x336B1F2B), blurRadius: 30),
                  ]))));
          })),

        // Декоративная линия под надписью
        Positioned(left: size.width * 0.2, right: size.width * 0.2,
          top: size.height * 0.36,
          child: AnimatedBuilder(animation: _glowCtrl, builder: (_, __) {
            return Container(height: 1.5, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent, kBurgundy.withOpacity(0.3 + _glowCtrl.value * 0.3),
                kBurgundy.withOpacity(0.6 + _glowCtrl.value * 0.3),
                kBurgundy.withOpacity(0.3 + _glowCtrl.value * 0.3), Colors.transparent])));
          })),

        // НАЧАТЬ / START
        Positioned(left: 24, right: 24, top: size.height * 0.45,
          child: _glowButton(
            label: tr('НАЧАТЬ', 'START'),
            ctrl: _pressStart, height: 68, fontSize: 38,
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PlayingFieldScreen())))),

        // РЕЙТИНГ
        Positioned(left: 40, right: 40, top: size.height * 0.75,
          child: _glowButton(
            label: tr('РЕЙТИНГ', 'RATING'),
            ctrl: _pressRating, height: 58, fontSize: 30,
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RatingScreen())))),

        // Профиль
        Positioned(left: 16, top: 52,
          child: _circleBtn('assets/images/backgrounds/profile.JPEG',
            () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())))),

        // Настройки
        Positioned(right: 16, top: 52,
          child: AnimatedBuilder(animation: _floatCtrl, builder: (_, __) =>
            Transform.rotate(angle: _floatCtrl.value * 0.5,
              child: _circleBtn('assets/images/backgrounds/setting.PNG',
                () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingScreen())))))),
      ]));
  }

  Widget _glowButton({required String label, required AnimationController ctrl,
      required double height, required double fontSize, required VoidCallback onTap}) {
    const depth = 7.0;
    return GestureDetector(
      onTap: () { ctrl.forward().then((_) => ctrl.reverse()); onTap(); },
      onTapDown: (_) => ctrl.forward(),
      onTapUp: (_) => ctrl.reverse(),
      onTapCancel: () => ctrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([ctrl, _glowCtrl]),
        builder: (_, __) {
          final p = ctrl.value;
          return SizedBox(height: height + depth, child: Stack(children: [
            // Нижняя грань
            Positioned(left: 0, top: depth, right: 0, bottom: 0,
              child: Container(decoration: BoxDecoration(
                color: const Color(0xFF3A0F18),
                borderRadius: BorderRadius.circular(height / 2)))),
            // Кнопка
            Positioned(left: 0, top: p * depth, right: 0,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF9B2E3F), Color(0xFF6B1F2B), Color(0xFF4A1520)]),
                  borderRadius: BorderRadius.circular(height / 2),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B1F2B).withOpacity(0.4 + _glowCtrl.value * 0.3),
                      blurRadius: 20, spreadRadius: 2),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8, offset: Offset(0, 6 - p * 6)),
                  ]),
                alignment: Alignment.center,
                child: Text(label, style: TextStyle(
                  color: Colors.white, fontSize: fontSize,
                  fontFamily: 'Cormorant', fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))
                  ])))),
          ]));
        }));
  }

  Widget _circleBtn(String asset, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(width: 68, height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          boxShadow: [BoxShadow(
            color: const Color(0xFF6B1F2B).withOpacity(0.4),
            blurRadius: 16, spreadRadius: 2)])));

  List<Widget> _floatingSymbols(Size size) {
    const symbols = ['麻', '將', '中', '發', '東', '南', '西', '北'];
    return List.generate(8, (i) => AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, __) {
        final t = (_floatCtrl.value + i * 0.125) % 1.0;
        final x = (size.width * 0.1) + (size.width * 0.8) * ((i * 0.137 + math.sin(t * 6 + i)) % 1.0).abs();
        final y = size.height * (1.1 - t * 1.3);
        final opacity = (math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.12;
        return Positioned(left: x, top: y, child: Opacity(opacity: opacity,
          child: Text(symbols[i], style: TextStyle(
            fontSize: 44 + (i % 3) * 12.0, color: const Color(0xFF6B1F2B)))));
      }));
  }
}