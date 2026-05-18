import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseService {
  static final FirebaseService _i = FirebaseService._();
  factory FirebaseService() => _i;
  FirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  String get displayName {
    final u = currentUser;
    if (u == null) return 'Гость';
    return u.displayName ?? u.email?.split('@').first ?? 'Игрок';
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final g = await GoogleSignIn().signIn();
      if (g == null) return null;
      final ga = await g.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: ga.accessToken, idToken: ga.idToken);
      final r = await _auth.signInWithCredential(cred);
      await _ensureDoc(r.user);
      return r;
    } catch (_) { return null; }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final raw   = generateNonce();
      final nonce = _sha256(raw);
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce);
      final cred = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken, rawNonce: raw,
        accessToken: apple.authorizationCode);
      final r = await _auth.signInWithCredential(cred);
      await _ensureDoc(r.user);
      return r;
    } catch (_) { return null; }
  }

  Future<String?> registerWithEmail(String email, String pass, String name) async {
    try {
      final r = await _auth.createUserWithEmailAndPassword(email:email, password:pass);
      await r.user?.updateDisplayName(name);
      await _ensureDoc(r.user, displayName:name);
      return null;
    } on FirebaseAuthException catch (e) { return _err(e.code); }
  }

  Future<String?> signInWithEmail(String email, String pass) async {
    try {
      await _auth.signInWithEmailAndPassword(email:email, password:pass);
      return null;
    } on FirebaseAuthException catch (e) { return _err(e.code); }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<void> saveScore(int score) async {
    final u = currentUser; if (u==null) return;
    final ref  = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    final prev = (snap.data()?['bestScore'] ?? 0) as int;
    if (score > prev) {
      await ref.set({
        'bestScore': score, 'score': score,
        'displayName': displayName,
        'email': u.email??'', 'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge:true));
    }
    await ref.collection('history').add({
      'score': score, 'at': FieldValue.serverTimestamp()});
    // Месячный рейтинг
    final mk = _monthKey();
    final mr = _db.collection('scores_monthly').doc(mk).collection('users').doc(u.uid);
    final ms = await mr.get();
    final prevMonth = (ms.data()?['score'] ?? 0) as int;
    await mr.set({'score': prevMonth + score, 'name': displayName,
      'updatedAt': FieldValue.serverTimestamp()});
  }

  String _monthKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}';
  }

  Stream<List<LeaderboardEntry>> topPlayers({int limit=50}) =>
    _db.collection('users').orderBy('bestScore',descending:true).limit(limit)
      .snapshots().map((s)=>s.docs.map(LeaderboardEntry.fromDoc).toList());

  Stream<LeaderboardEntry?> myProfile() {
    final u = currentUser; if (u==null) return const Stream.empty();
    return _db.collection('users').doc(u.uid).snapshots()
      .map((d)=>d.exists?LeaderboardEntry.fromDoc(d):null);
  }

  Future<void> _ensureDoc(User? user, {String? displayName}) async {
    if (user==null) return;
    final ref = _db.collection('users').doc(user.uid);
    if (!(await ref.get()).exists) {
      await ref.set({
        'displayName': displayName??user.displayName??user.email?.split('@').first??'Игрок',
        'email': user.email??'', 'bestScore': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _err(String code) => const {
    'email-already-in-use': 'Email уже используется',
    'invalid-email':        'Неверный email',
    'weak-password':        'Пароль слишком простой',
    'user-not-found':       'Пользователь не найден',
    'wrong-password':       'Неверный пароль',
    'too-many-requests':    'Слишком много попыток',
  }[code] ?? 'Ошибка: $code';

  String _sha256(String s) => sha256.convert(utf8.encode(s)).toString();
}

class LeaderboardEntry {
  final String uid, name; final int score;
  LeaderboardEntry({required this.uid,required this.name,required this.score});
  factory LeaderboardEntry.fromDoc(doc) {
    final d = doc.data() as Map<String,dynamic>;
    return LeaderboardEntry(uid:doc.id,
      name:d['displayName']??'Игрок', score:(d['bestScore']??0)as int);
  }
}