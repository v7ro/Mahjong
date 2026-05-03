import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});
  @override State<RatingScreen> createState() => _RatingState();
}

class _RatingState extends State<RatingScreen>
    with SingleTickerProviderStateMixin {
  static const Color kBurgundy = Color(0xFF6B1F2B);
  late final TabController _tabs;
  final _fs = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }
  @override void dispose() { _tabs.dispose(); super.dispose(); }

  // Текущий месяц как ключ: "2025-05"
  String get _monthKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kBurgundy),
        title: const Text('рейтинг', style: TextStyle(
          fontFamily: 'Aboreto', fontSize: 28, color: kBurgundy)),
        bottom: TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontFamily: 'Aboreto', fontSize: 13),
          labelColor: kBurgundy,
          unselectedLabelColor: Colors.white60,
          indicatorColor: kBurgundy,
          tabs: const [
            Tab(text: 'этот месяц'),
            Tab(text: 'всё время'),
          ],
        ),
      ),
      body: Stack(children: [
        Positioned.fill(child: Opacity(opacity: 0.8,
          child: Image.asset('assets/images/backgrounds/rating.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (_,__,___) => Container(color: const Color(0xFF1a0a05))))),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.35))),

        SafeArea(child: Column(children: [
          const SizedBox(height: 8),
          // Мой результат
          StreamBuilder<LeaderboardEntry?>(
            stream: _fs.myProfile(),
            builder: (ctx, snap) {
              if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
              final me = snap.data!;
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kBurgundy.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 1)),
                child: Row(children: [
                  const Icon(Icons.person_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(me.name, style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontFamily: 'Aboreto'))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${me.score}', style: const TextStyle(
                      color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('очков', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ]),
                ]));
            },
          ),

          // Табы
          Expanded(child: TabBarView(
            controller: _tabs,
            children: [
              _LeaderList(
                stream: FirebaseFirestore.instance
                  .collection('scores_monthly')
                  .doc(_monthKey)
                  .collection('users')
                  .orderBy('score', descending: true)
                  .limit(50)
                  .snapshots()
                  .map((s) => s.docs.map((d) {
                    final data = d.data();
                    return LeaderboardEntry(
                      uid: d.id,
                      name: data['name'] ?? 'Игрок',
                      score: (data['score'] ?? 0) as int);
                  }).toList()),
                emptyText: 'В этом месяце ещё нет записей',
              ),
              _LeaderList(
                stream: _fs.topPlayers(),
                emptyText: 'Пока нет записей',
              ),
            ],
          )),
        ])),
      ]),
    );
  }
}

class _LeaderList extends StatelessWidget {
  final Stream<List<LeaderboardEntry>> stream;
  final String emptyText;
  static const Color kBurgundy = Color(0xFF6B1F2B);

  const _LeaderList({required this.stream, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: kBurgundy));
        if (!snap.hasData || snap.data!.isEmpty)
          return Center(child: Text(emptyText,
            style: const TextStyle(color: Colors.white70, fontSize: 16)));

        final list   = snap.data!;
        final myUid  = FirebaseAuth.instance.currentUser?.uid;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final e    = list[i];
            final isMe = e.uid == myUid;
            Color? medalC;
            if      (i == 0) medalC = const Color(0xFFFFD700);
            else if (i == 1) medalC = const Color(0xFFC0C0C0);
            else if (i == 2) medalC = const Color(0xFFCD7F32);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isMe ? kBurgundy.withOpacity(0.85) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: isMe ? Border.all(color: Colors.white.withOpacity(0.4), width: 1.5) : null),
              child: ListTile(
                dense: true,
                leading: medalC != null
                  ? Icon(Icons.emoji_events_rounded, color: medalC, size: 26)
                  : SizedBox(width: 26, child: Text('${i+1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white60 : Colors.grey.shade500))),
                title: Text(e.name, style: TextStyle(
                  fontFamily: 'Aboreto', fontSize: 13,
                  color: isMe ? Colors.white : Colors.black87,
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${e.score}', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: isMe ? Colors.amber : kBurgundy)),
                  const Text('очков', style: TextStyle(fontSize: 9, color: Colors.grey)),
                ]),
              ));
          });
      });
  }
}