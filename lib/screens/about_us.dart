import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  static const kBurgundy = Color(0xFF6B1F2B);
  static const _githubUrl = 'https://github.com/v7ro/Mahjong';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kBurgundy),
        title: const Text('о нас', style: TextStyle(
          fontFamily: 'Aboreto', fontSize: 26, color: kBurgundy))),
      body: Stack(children: [
        Positioned.fill(child: Image.asset(
          'assets/images/backgrounds/setting_bg.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF1a0a05)))),
        Positioned.fill(child: Container(color: const Color(0x44000000))),
        SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('麻將', style: TextStyle(
              fontSize: 72, color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 12)])),
            const SizedBox(height: 16),
            const Text('Mahjong Solitaire',
              style: TextStyle(
                fontSize: 28, color: Colors.white,
                fontFamily: 'Aboreto', letterSpacing: 2)),
            const SizedBox(height: 12),
            Text('Классический маджонг-пасьянс.\nУбери все плитки с доски.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, color: Colors.white.withOpacity(0.85),
                fontFamily: 'Cormorant', height: 1.5)),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: _githubUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ссылка скопирована')));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: kBurgundy.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2))),
                child: Column(children: [
                  const Icon(Icons.code_rounded,
                    color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  const Text('GitHub',
                    style: TextStyle(
                      color: Colors.white, fontSize: 20,
                      fontFamily: 'Aboreto', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_githubUrl,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13, fontFamily: 'Cormorant')),
                  const SizedBox(height: 8),
                  Text('нажми чтобы скопировать',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12, fontFamily: 'Cormorant')),
                ]))),
          ])))),
      ]));
  }
}
