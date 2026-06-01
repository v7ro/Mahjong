import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n.dart';
import '../services/music_service.dart';
import 'about_us.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _State();
}

class _State extends State<SettingScreen> with TickerProviderStateMixin {
  static const Color kBurgundy = Color(0xFF6B1F2B);

  bool isMusicOn = true;
  bool isSoundOn = true;

  late final List<AnimationController> _presses;

  @override
  void initState() {
    super.initState();

    AppLocale().addListener(() {
      if (mounted) setState(() {});
    });

    _presses = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.0,
        upperBound: 1.0,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _presses) c.dispose();
    super.dispose();
  }

  void _openLanguageMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: kBurgundy.withOpacity(0.65),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LANGUAGE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 22,
                      fontFamily: 'Aboreto',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _langTile('Русский', AppLocale().isRu, () {
                    AppLocale().setRu();
                    setState(() {});
                    Navigator.pop(context);
                  }),

                  const Divider(color: Colors.white24),

                  _langTile('English', !AppLocale().isRu, () {
                    AppLocale().setEn();
                    setState(() {});
                    Navigator.pop(context);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _langTile(String label, bool active, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.white70,
          fontSize: 22,
          fontFamily: 'Forum',
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: active
          ? const Icon(Icons.check_rounded, color: Colors.white)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final btnW = MediaQuery.of(context).size.width - 48;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kBurgundy),
        title: Text(
          tr('НАСТРОЙКИ', 'SETTINGS'),
          style: TextStyle(
            fontFamily: AppLocale().isRu ? 'Forum' : 'Aboreto',
            fontSize: 34,
            color: kBurgundy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/setting_bg.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    _glassBtn(
                      0,
                      btnW,
                      tr('ЯЗЫК', 'LANGUAGE'),
                      _openLanguageMenu,
                    ),

                    const SizedBox(height: 30),

                    _glassSwitch(
                      1,
                      btnW,
                      tr('МУЗЫКА', 'MUSIC'),
                      isMusicOn,
                      (v) {
                        setState(() => isMusicOn = v);
                        MusicService().setOn(v);
                      },
                    ),

                    const SizedBox(height: 30),

                    _glassSwitch(
                      2,
                      btnW,
                      tr('ЗВУКИ', 'SOUNDS'),
                      isSoundOn,
                      (v) => setState(() => isSoundOn = v),
                    ),

                    const SizedBox(height: 30),

                    _glassBtn(
                      3,
                      btnW,
                      tr('О НАС', 'ABOUT US'),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutUsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassBtn(
    int i,
    double w,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        _presses[i].forward().then((_) => _presses[i].reverse());
        onTap();
      },
      onTapDown: (_) => _presses[i].forward(),
      onTapUp: (_) => _presses[i].reverse(),
      onTapCancel: () => _presses[i].reverse(),
      child: AnimatedBuilder(
        animation: _presses[i],
        builder: (_, __) {
          final p = _presses[i].value;

          return Transform.translate(
            offset: Offset(0, p * 4),
            child: Container(
              width: w,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kBurgundy.withOpacity(0.55),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontFamily: 'Forum',
                  letterSpacing: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _glassSwitch(
    int i,
    double w,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      width: w,
      height: 64,
      decoration: BoxDecoration(
        color: kBurgundy.withOpacity(0.62),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontFamily: 'Forum',
                letterSpacing: 2,
              ),
            ),
          ),

          Positioned(
            right: 14,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: Colors.white30,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}  void _openLanguageMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kBurgundy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2))),
          const Text('LANGUAGE', style: TextStyle(
            color: Colors.white, fontSize: 22,
            fontFamily: 'Aboreto', letterSpacing: 2)),
          const SizedBox(height: 12),
          _langTile('Русский', AppLocale().isRu, () {
            AppLocale().setRu(); setState(() {}); Navigator.pop(context);
          }),
          const Divider(color: Colors.white24),
          _langTile('English', !AppLocale().isRu, () {
            AppLocale().setEn(); setState(() {}); Navigator.pop(context);
          }),
        ])));
  }

  Widget _langTile(String label, bool active, VoidCallback onTap) =>
    ListTile(
      onTap: onTap,
      title: Text(label, style: TextStyle(
        color: active ? Colors.white : Colors.white70,
        fontSize: 22, fontFamily: 'Cormorant',
        fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      trailing: active
        ? const Icon(Icons.check_rounded, color: Colors.white) : null);

  @override
  Widget build(BuildContext context) {
    final btnW = MediaQuery.of(context).size.width - 48.0;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kBurgundy),
        title: Text(
          tr('НАСТРОЙКИ', 'SETTINGS'),
          style: TextStyle(
            fontFamily: AppLocale().isRu ? 'Forum' : 'Aboreto',
            fontWeight: FontWeight.bold,
            fontSize: 34, color: kBurgundy)),
        flexibleSpace: ClipRect(child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10)))),
      body: Stack(children: [
        Positioned.fill(child: Image.asset(
          'assets/images/backgrounds/setting_bg.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFFF0E8DC)))),
        SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _3dBtn(0, btnW, tr('ЯЗЫК', 'LANGUAGE'), _openLanguageMenu),
              const SizedBox(height: 20),
              _3dSwitch(1, btnW, tr('МУЗЫКА', 'MUSIC'), isMusicOn, (v) {
                setState(() => isMusicOn = v);
                MusicService().setOn(v);
              }),
              const SizedBox(height: 20),
              _3dSwitch(2, btnW, tr('ЗВУКИ', 'SOUNDS'), isSoundOn,
                (v) => setState(() => isSoundOn = v)),
              const SizedBox(height: 20),
              _3dBtn(3, btnW, tr('О НАС', 'ABOUT US'), () =>
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutUsScreen()))),
            ])))),
      ]));
  }

  Widget _3dBtn(int i, double w, String label, VoidCallback onTap) {
    const h = 64.0, depth = 6.0;
    return GestureDetector(
      onTap: () {
        _presses[i].forward().then((_) => _presses[i].reverse());
        onTap();
      },
      onTapDown: (_) => _presses[i].forward(),
      onTapUp: (_) => _presses[i].reverse(),
      onTapCancel: () => _presses[i].reverse(),
      child: AnimatedBuilder(
        animation: _presses[i],
        builder: (_, __) {
          final p = _presses[i].value;
          return SizedBox(
            width: w, height: h + depth,
            child: Stack(children: [
              Positioned(left: 0, top: depth, right: 0, bottom: 0,
                child: Container(decoration: BoxDecoration(
                  color: kBurgundyBot,
                  borderRadius: BorderRadius.circular(32)))),
              Positioned(left: 0, top: p * depth, right: 0,
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [kBurgundyTop, kBurgundy]),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white24, width: 1.5)),
                  alignment: Alignment.center,
                  child: Text(label, style: const TextStyle(
                    color: Colors.white, fontSize: 28,
                    fontFamily: 'Forum', fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [Shadow(
                      color: Color(0x44000000),
                      blurRadius: 4, offset: Offset(0, 2))])))),
            ]));
        }));
  }

  Widget _3dSwitch(int i, double w, String label, bool value,
      ValueChanged<bool> onChanged) {
    const h = 64.0, depth = 6.0;
    return SizedBox(
      width: w, height: h + depth,
      child: Stack(children: [
        Positioned(left: 0, top: depth, right: 0, bottom: 0,
          child: Container(decoration: BoxDecoration(
            color: kBurgundyBot,
            borderRadius: BorderRadius.circular(32)))),
        Positioned(left: 0, top: 0, right: 0,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [kBurgundyTop, kBurgundy]),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white24, width: 1.5)),
            child: Stack(alignment: Alignment.center, children: [
              Text(label, style: const TextStyle(
                color: Colors.white, fontSize: 28,
                fontFamily: 'Forum', fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [Shadow(
                  color: Color(0x44000000),
                  blurRadius: 4, offset: Offset(0, 2))])),
              Positioned(right: 16,
                child: Switch(
                  value: value,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white38,
                  inactiveThumbColor: Colors.white54,
                  inactiveTrackColor: Colors.white24,
                  onChanged: onChanged)),
            ]))),
      ]));
  }
}
