import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../l10n.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _State();
}

class _State extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  static const kBurgundy = Color(0xFF6B1F2B);
  final _fs = FirebaseService();
  final _nameCtrl = TextEditingController();
  bool _editing = false, _saving = false;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _fs.displayName;
    AppLocale().addListener(() { if (mounted) setState(() {}); });
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final n = _nameCtrl.text.trim();
    if (n.isEmpty) return;
    setState(() => _saving = true);
    await FirebaseAuth.instance.currentUser?.updateDisplayName(n);
    final u = _fs.currentUser;
    if (u != null) {
      await FirebaseFirestore.instance
        .collection('users').doc(u.uid).update({'displayName': n});
    }
    setState(() { _editing = false; _saving = false; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Имя обновлено', 'Name updated'))));
  }

  Future<void> _signOut() async {
    await _fs.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _fs.currentUser;
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kBurgundy),
        title: Text(tr('ПРОФИЛЬ', 'PROFILE'),
          style: const TextStyle(
            fontFamily: 'Cormorant', fontSize: 33,
            color: kBurgundy, fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Color(0x336B1F2B), blurRadius: 8)]))),
      body: Stack(children: [
        Positioned.fill(child: Image.asset(
          'assets/images/backgrounds/profile_bg.jpeg',
          fit: BoxFit.cover, alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFFF5EFE6)))),
        Positioned.fill(child: SafeArea(
          child: user == null ? _guest() : _user(user))),
      ]));
  }

  Widget _guest() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) => Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: kBurgundy,
            boxShadow: [BoxShadow(
              color: kBurgundy.withValues(
                alpha: 0.3 + _glowCtrl.value * 0.3),
              blurRadius: 20, spreadRadius: 4)]),
          child: const Icon(Icons.person_rounded,
            color: Colors.white, size: 50))),
      const SizedBox(height: 20),
      Text(tr('вы не вошли в аккаунт', 'you are not logged in'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: kBurgundy, fontSize: 21,
          fontFamily: 'Cormorant', fontWeight: FontWeight.w600)),
      const SizedBox(height: 32),
      _actionBtn(
        label: tr('войти / регистрация', 'sign in / register'),
        onTap: () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen())),
        primary: true),
    ])));

  Widget _user(User user) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
    child: Column(children: [
      const SizedBox(height: 8),
      AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) => Container(
          width: 86, height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: kBurgundy,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(
              color: kBurgundy.withValues(
                alpha: 0.25 + _glowCtrl.value * 0.25),
              blurRadius: 24, spreadRadius: 4)]),
          child: const Icon(Icons.person_rounded,
            color: Colors.white, size: 46))),
      const SizedBox(height: 20),

      _card(
        label: tr('ИМЯ', 'NAME'),
        child: _editing
          ? Row(children: [
              Expanded(child: TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: kBurgundy, fontSize: 21,
                  fontFamily: 'Cormorant', fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: kBurgundy.withValues(alpha: 0.4))),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.8)))),
              const SizedBox(width: 8),
              _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: kBurgundy, strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.check_rounded, color: kBurgundy),
                    onPressed: _saveName),
              IconButton(
                icon: Icon(Icons.close,
                  color: kBurgundy.withValues(alpha: 0.5)),
                onPressed: () => setState(() => _editing = false)),
            ])
          : Row(children: [
              Expanded(child: Text(_fs.displayName,
                style: const TextStyle(color: kBurgundy, fontSize: 23,
                  fontFamily: 'Cormorant', fontWeight: FontWeight.bold))),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                  color: kBurgundy.withValues(alpha: 0.5), size: 20),
                onPressed: () => setState(() => _editing = true)),
            ])),

      const SizedBox(height: 12),
      _card(
        label: 'EMAIL',
        child: Text(user.email ?? '',
          style: TextStyle(
            color: kBurgundy.withValues(alpha: 0.85),
            fontSize: 16, fontFamily: 'Cormorant'))),

      const SizedBox(height: 12),
      StreamBuilder<LeaderboardEntry?>(
        stream: _fs.myProfile(),
        builder: (ctx, snap) => _card(
          label: tr('ЛУЧШИЙ СЧЁТ', 'BEST SCORE'),
          child: Text('${snap.data?.score ?? 0}',
            style: const TextStyle(color: kBurgundy, fontSize: 33,
              fontFamily: 'Cormorant', fontWeight: FontWeight.bold)))),

      const SizedBox(height: 12),
      _card(
        label: tr('ЯЗЫК', 'LANGUAGE'),
        child: Row(children: [
          const Spacer(),
          _langBtn('RU', AppLocale().isRu),
          const SizedBox(width: 8),
          _langBtn('EN', !AppLocale().isRu),
        ])),

      const SizedBox(height: 24),
      _actionBtn(
        label: tr('выйти из аккаунта', 'sign out'),
        icon: Icons.logout_rounded,
        onTap: _signOut,
        primary: true),
    ]));

  Widget _card({required String label, required Widget child}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBurgundy.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(
          color: kBurgundy.withValues(alpha: 0.08),
          blurRadius: 12, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
            color: kBurgundy.withValues(alpha: 0.55),
            fontSize: 12, fontFamily: 'Aboreto', letterSpacing: 1.5)),
          const SizedBox(height: 6),
          child,
        ]));

  Widget _langBtn(String code, bool active) => GestureDetector(
    onTap: () {
      code == 'RU' ? AppLocale().setRu() : AppLocale().setEn();
      setState(() {});
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: active ? kBurgundy : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? kBurgundy : kBurgundy.withValues(alpha: 0.3)),
        boxShadow: active
          ? [BoxShadow(
              color: kBurgundy.withValues(alpha: 0.3),
              blurRadius: 8)]
          : []),
      child: Text(code, style: TextStyle(
        color: active ? Colors.white : kBurgundy.withValues(alpha: 0.6),
        fontFamily: 'Aboreto', fontSize: 14,
        fontWeight: FontWeight.bold))));

  Widget _actionBtn({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool primary = false}) =>
    SizedBox(width: double.infinity, child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: primary
            ? kBurgundy
            : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary
              ? kBurgundy
              : kBurgundy.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(
            color: primary
              ? kBurgundy.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.05),
            blurRadius: primary ? 12 : 4,
            offset: const Offset(0, 3))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon,
                color: primary
                  ? Colors.white
                  : kBurgundy.withValues(alpha: 0.7),
                size: 20),
              const SizedBox(width: 8)],
            Text(label, style: TextStyle(
              color: primary
                ? Colors.white
                : kBurgundy.withValues(alpha: 0.85),
              fontSize: 17, fontFamily: 'Cormorant',
              fontWeight: FontWeight.w600)),
          ]))));
}