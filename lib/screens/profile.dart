import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  static const Color kBurgundy = Color(0xFF6B1F2B);
  final _fs = FirebaseService();
  final _nameCtrl = TextEditingController();
  bool _editingName = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _fs.displayName;
  }
  @override void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    // Update in Firestore too
    final u = _fs.currentUser;
    if (u != null) {
      await FirebaseService().myProfile().first; // ensure doc exists
    }
    setState(() { _editingName = false; _saving = false; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Имя обновлено')));
  }

  Future<void> _signOut() async {
    await _fs.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _fs.currentUser;
    final isGuest = user == null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kBurgundy),
        title: const Text('профиль', style: TextStyle(
          fontFamily: 'Aboreto', fontSize: 28, color: kBurgundy)),
      ),
      body: Stack(children: [
        Positioned.fill(child: Image.asset(
          'assets/images/backgrounds/profile_bg.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (_,__,___) => Container(color: const Color(0xFF1a0a05)))),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.30))),

        SafeArea(child: isGuest ? _guestView() : _userView(user)),
      ]),
    );
  }

  // ── Гость ──────────────────────────────────────────────
  Widget _guestView() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.person_outline, color: Colors.white70, size: 80),
      const SizedBox(height: 16),
      const Text('вы не вошли в аккаунт', textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Aboreto')),
      const SizedBox(height: 32),
      _btn('войти / регистрация', () => Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()))),
    ]),
  ));

  // ── Авторизованный пользователь ─────────────────────────
  Widget _userView(User user) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(children: [
      const SizedBox(height: 8),

      // Аватар
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kBurgundy.withOpacity(0.8),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 50)),
      const SizedBox(height: 16),

      // Имя
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('имя', style: TextStyle(color: Colors.white60, fontSize: 12,
          fontFamily: 'Aboreto', letterSpacing: 1)),
        const SizedBox(height: 8),
        if (_editingName)
          Row(children: [
            Expanded(child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white)),
                filled: true, fillColor: Colors.white.withOpacity(0.1),
              ),
            )),
            const SizedBox(width: 8),
            _saving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : IconButton(icon: const Icon(Icons.check, color: Colors.white), onPressed: _saveName),
            IconButton(icon: const Icon(Icons.close, color: Colors.white60),
              onPressed: () => setState(() { _editingName = false; _nameCtrl.text = _fs.displayName; })),
          ])
        else
          Row(children: [
            Expanded(child: Text(_fs.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(Icons.edit, color: Colors.white60, size: 20),
              onPressed: () => setState(() => _editingName = true)),
          ]),
      ])),

      const SizedBox(height: 12),

      // Email
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('email', style: TextStyle(color: Colors.white60, fontSize: 12,
          fontFamily: 'Aboreto', letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(user.email ?? 'не указан',
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      ])),

      const SizedBox(height: 12),

      // Статистика из Firestore
      StreamBuilder<LeaderboardEntry?>(
        stream: _fs.myProfile(),
        builder: (ctx, snap) {
          final score = snap.data?.score ?? 0;
          return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('статистика', style: TextStyle(color: Colors.white60, fontSize: 12,
              fontFamily: 'Aboreto', letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(children: [
              _stat('лучший счёт', '$score'),
              const SizedBox(width: 16),
              _stat('очки', '$score'),
            ]),
          ]));
        },
      ),

      const SizedBox(height: 24),

      // Выход
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, color: Colors.white70),
        label: const Text('выйти из аккаунта',
          style: TextStyle(color: Colors.white70, fontFamily: 'Aboreto')),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      )),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.40),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1)),
    child: child);

  Widget _stat(String label, String value) => Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.amber, fontSize: 22,
        fontWeight: FontWeight.bold)),
    ]));

  Widget _btn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity, child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kBurgundy,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(label, style: const TextStyle(color: Colors.white,
        fontSize: 16, fontFamily: 'Aboreto'))));
}