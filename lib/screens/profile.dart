import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../l10n.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _State();
}

class _State extends State<ProfileScreen> {
  static const kBurgundy = Color(0xFF6B1F2B);
  final _fs = FirebaseService();
  final _nameCtrl = TextEditingController();
  bool _editing = false, _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _fs.displayName;
    AppLocale().addListener(() { if (mounted) setState(() {}); });
  }
  @override void dispose() { _nameCtrl.dispose(); super.dispose(); }

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

  Future<void> _resetTutorial() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('tutorial_done', false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Обучение сброшено', 'Tutorial reset'))));
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
        title: Text(
          tr('ПРОФИЛЬ', 'PROFILE'),
          style: const TextStyle(
            fontFamily: 'Cormorant', fontSize: 30,
            color: kBurgundy, fontWeight: FontWeight.bold))),
      body: Stack(children: [
        Positioned.fill(child: Image.asset(
          'assets/images/backgrounds/profile_bg.jpeg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFFF5EFE6)))),
        Positioned.fill(child: SafeArea(
          child: user == null ? _guest() : _user(user))),
      ]));
  }

  Widget _guest() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: kBurgundy),
        child: const Icon(Icons.person_rounded,
          color: Colors.white, size: 50)),
      const SizedBox(height: 20),
      Text(tr('вы не вошли в аккаунт', 'you are not logged in'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kBurgundy, fontSize: 20,
          fontFamily: 'Cormorant', fontWeight: FontWeight.w600)),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen())),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBurgundy,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12))),
        child: Text(tr('войти / регистрация', 'sign in / register'),
          style: const TextStyle(
            color: Colors.white, fontSize: 18,
            fontFamily: 'Cormorant', fontWeight: FontWeight.w600)))),
    ])));

  Widget _user(User user) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
    child: Column(children: [
      const SizedBox(height: 8),
      // Аватар
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: kBurgundy,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(
            color: kBurgundy.withOpacity(0.4),
            blurRadius: 16, offset: const Offset(0, 4))]),
        child: const Icon(Icons.person_rounded,
          color: Colors.white, size: 44)),
      const SizedBox(height: 20),

      // Карточка имени
      _card(
        label: tr('ИМЯ', 'NAME'),
        child: _editing
          ? Row(children: [
              Expanded(child: TextField(
                controller: _nameCtrl,
                style: const TextStyle(
                  color: kBurgundy, fontSize: 20,
                  fontFamily: 'Cormorant', fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: kBurgundy.withOpacity(0.5))),
                  filled: true, fillColor: Colors.white.withOpacity(0.8)))),
              const SizedBox(width: 8),
              _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: kBurgundy, strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.check, color: kBurgundy),
                    onPressed: _saveName),
              IconButton(
                icon: Icon(Icons.close, color: kBurgundy.withOpacity(0.5)),
                onPressed: () => setState(() => _editing = false)),
            ])
          : Row(children: [
              Expanded(child: Text(_fs.displayName,
                style: const TextStyle(
                  color: kBurgundy, fontSize: 26,
                  fontFamily: 'Cormorant', fontWeight: FontWeight.bold))),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                  color: kBurgundy.withOpacity(0.5), size: 20),
                onPressed: () => setState(() => _editing = true)),
            ])),

      const SizedBox(height: 10),
      _card(label: 'EMAIL',
        child: Text(user.email ?? tr('не указан', 'not set'),
          style: TextStyle(
            color: kBurgundy.withOpacity(0.9), fontSize: 20,
            fontFamily: 'Cormorant', fontWeight: FontWeight.w500))),

      const SizedBox(height: 10),
      StreamBuilder<LeaderboardEntry?>(
        stream: _fs.myProfile(),
        builder: (ctx, snap) => _card(
          label: tr('ЛУЧШИЙ СЧЁТ', 'BEST SCORE'),
          child: Text('${snap.data?.score ?? 0}',
            style: const TextStyle(
              color: kBurgundy, fontSize: 32,
              fontFamily: 'Cormorant', fontWeight: FontWeight.bold)))),

      const SizedBox(height: 10),
      _card(label: tr('ЯЗЫК', 'LANGUAGE'),
        child: Row(children: [
          const Spacer(),
          _langBtn('RU', AppLocale().isRu),
          const SizedBox(width: 8),
          _langBtn('EN', !AppLocale().isRu),
        ])),

      const SizedBox(height: 20),
      _outlineBtn(
        icon: Icons.refresh_rounded,
        label: tr('сбросить обучение', 'reset tutorial'),
        onTap: _resetTutorial),
      const SizedBox(height: 10),
      _outlineBtn(
        icon: Icons.logout_rounded,
        label: tr('выйти из аккаунта', 'sign out'),
        onTap: _signOut,
        primary: true),
    ]));

  Widget _card({required String label, required Widget child}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        // Лёгкий тёплый белый — фон виден через него
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBurgundy.withOpacity(0.2)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
          color: kBurgundy.withOpacity(0.7), fontSize: 13,
          fontFamily: 'Aboreto', letterSpacing: 1.5)),
        const SizedBox(height: 6),
        child,
      ]));

  Widget _langBtn(String code, bool active) => GestureDetector(
    onTap: () {
      code == 'RU' ? AppLocale().setRu() : AppLocale().setEn();
      setState(() {});
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: active ? kBurgundy : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? kBurgundy : kBurgundy.withOpacity(0.3))),
      child: Text(code, style: TextStyle(
        color: active ? Colors.white : kBurgundy.withOpacity(0.6),
        fontFamily: 'Aboreto', fontSize: 14,
        fontWeight: FontWeight.bold))));

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false}) =>
    SizedBox(width: double.infinity, child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary ? kBurgundy : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary ? kBurgundy : kBurgundy.withOpacity(0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
            color: primary ? Colors.white : kBurgundy.withOpacity(0.7),
            size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            color: primary ? Colors.white : kBurgundy.withOpacity(0.8),
            fontSize: 16, fontFamily: 'Cormorant',
            fontWeight: FontWeight.w600)),
        ]))));
}