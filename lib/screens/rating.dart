import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../l10n.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _State();
}

class _State extends State<RatingScreen>
    with SingleTickerProviderStateMixin {
  static const kBurgundy = Color(0xFF6B1F2B);

  late final TabController _tabs;
  final _fs = FirebaseService();

  @override
  void initState() {
    super.initState();

    _tabs = TabController(length: 2, vsync: this);

    AppLocale().addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _month {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: kBurgundy),
          title: Text(
            tr('РЕЙТИНГ', 'rating'),
            style: TextStyle(
              fontFamily: AppLocale().isRu ? 'Forum' : 'Aboreto',
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: kBurgundy,
            ),
          ),
          bottom: TabBar(
            controller: _tabs,
            labelStyle: const TextStyle(
              fontFamily: 'Forum',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Forum',
              fontSize: 15,
            ),
            labelColor: kBurgundy,
            unselectedLabelColor: const Color(0x99000000),
            indicatorColor: kBurgundy,
            tabs: [
              Tab(text: tr('этот месяц', 'this month')),
              Tab(text: tr('всё время', 'all time')),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgrounds/rating.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1a0a05),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  StreamBuilder<LeaderboardEntry?>(
                    stream: _fs.myProfile(),
                    builder: (ctx, snap) {
                      if (!snap.hasData || snap.data == null) {
                        return const SizedBox.shrink();
                      }

                      final me = snap.data!;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),

                        decoration: BoxDecoration(
                          color: kBurgundy.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0x4DFFFFFF),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              color: Color(0xB3FFFFFF),
                              size: 18,
                            ),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                me.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Aboreto',
                                ),
                              ),
                            ),

                            Text(
                              '${me.score} ${tr("очков", "pts")}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Forum',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _list(
                          FirebaseFirestore.instance
                              .collection('scores_monthly')
                              .doc(_month)
                              .collection('users')
                              .orderBy('score', descending: true)
                              .limit(50)
                              .snapshots()
                              .map((s) => s.docs.map((d) {
                                    final data = d.data();
                                    return LeaderboardEntry(
                                      uid: d.id,
                                      name: data['name'] ??
                                          tr('Игрок', 'Player'),
                                      score: (data['score'] ?? 0) as int,
                                    );
                                  }).toList()),
                          tr('В этом месяце нет записей',
                              'No records this month'),
                        ),

                        _list(
                          _fs.topPlayers(),
                          tr('Нет записей', 'No records'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _list(Stream<List<LeaderboardEntry>> stream, String empty) =>
      StreamBuilder<List<LeaderboardEntry>>(
        stream: stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kBurgundy),
            );
          }

          if (!snap.hasData || snap.data!.isEmpty) {
            return Center(
              child: Text(
                empty,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 17,
                  fontFamily: 'Aboreto',
                ),
              ),
            );
          }

          final list = snap.data!;
          final myUid = FirebaseAuth.instance.currentUser?.uid;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final e = list[i];
              final isMe = e.uid == myUid;

              Color? mc;
              if (i == 0) mc = const Color(0xFFFFD700);
              else if (i == 1) mc = const Color(0xFFC0C0C0);
              else if (i == 2) mc = const Color(0xFFCD7F32);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),

                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),

                decoration: BoxDecoration(
                  color: isMe
                      ? kBurgundy.withOpacity(0.65)
                      : Colors.white.withOpacity(0.65),

                  borderRadius: BorderRadius.circular(42),

                  border: isMe
                      ? Border.all(
                          color: const Color(0x4DFFFFFF),
                          width: 1.5,
                        )
                      : Border.all(
                          color: kBurgundy.withOpacity(0.2),
                        ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,

                  leading: mc != null
                      ? Icon(Icons.emoji_events_rounded,
                          color: mc, size: 24)
                      : SizedBox(
                          width: 24,
                          child: Text(
                            '${i + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isMe
                                  ? const Color(0x99FFFFFF)
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),

                  title: Text(
                    e.name,
                    style: TextStyle(
                      fontFamily: 'Forum',
                      fontSize: 17,
                      color: isMe ? Colors.white : Colors.black87,
                      fontWeight:
                          isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),

                  trailing: Text(
                    '${e.score}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Aboreto',
                      color: isMe ? Colors.amber : kBurgundy,
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
}      bottom: TabBar(
        controller: _tabs,
        labelStyle: const TextStyle(fontFamily: 'Cormorant', fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Cormorant', fontSize: 15),
        labelColor: kBurgundy,
        unselectedLabelColor: const Color(0x99000000),
        indicatorColor: kBurgundy,
        tabs: [
          Tab(text: tr('этот месяц', 'this month')),
          Tab(text: tr('всё время', 'all time')),
        ])),
    body: Stack(children: [
      Positioned.fill(child: Image.asset(
        'assets/images/backgrounds/rating.jpeg', fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(color: Color(0xFF1a0a05))))),

      SafeArea(child: Column(children: [
        const SizedBox(height: 6),
        StreamBuilder<LeaderboardEntry?>(
          stream: _fs.myProfile(),
          builder: (ctx, snap) {
            if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
            final me = snap.data!;
            return Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kBurgundy.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33FFFFFF))),
              child: Row(children: [
                const Icon(Icons.person_rounded,
                  color: const Color(0xB3FFFFFF), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(me.name, style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontFamily: 'Aboreto'))),
                Text('${me.score} ${tr("очков", "pts")}',
                  style: const TextStyle(color: Colors.amber,
                    fontSize: 16, fontWeight: FontWeight.bold,
                    fontFamily: 'Cormorant')),
              ]));
          }),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _list(
            FirebaseFirestore.instance
              .collection('scores_monthly').doc(_month)
              .collection('users')
              .orderBy('score', descending: true).limit(50)
              .snapshots().map((s) => s.docs.map((d) {
                final data = d.data();
                return LeaderboardEntry(uid: d.id,
                  name: data['name'] ?? tr('Игрок', 'Player'),
                  score: (data['score'] ?? 0) as int);
              }).toList()),
            tr('В этом месяце нет записей', 'No records this month')),
          _list(_fs.topPlayers(), tr('Нет записей', 'No records')),
        ])),
      ])),
    ]));

  Widget _list(Stream<List<LeaderboardEntry>> stream, String empty) =>
    StreamBuilder<List<LeaderboardEntry>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(
            color: kBurgundy));
        if (!snap.hasData || snap.data!.isEmpty)
          return Center(child: Text(empty, style: TextStyle(
            color: const Color(0xB3FFFFFF), fontSize: 17, fontFamily: 'Aboreto')));
        final list = snap.data!;
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final e = list[i];
            final isMe = e.uid == myUid;
            Color? mc;
            if (i == 0) mc = const Color(0xFFFFD700);
            else if (i == 1) mc = const Color(0xFFC0C0C0);
            else if (i == 2) mc = const Color(0xFFCD7F32);
            return Container(
              margin: EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                color: isMe
                  ? kBurgundy.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(11),
                border: isMe
                  ? Border.all(
                      color: const Color(0x4DFFFFFF), width: 1.5)
                  : null),
              child: ListTile(dense: true,
                leading: mc != null
                  ? Icon(Icons.emoji_events_rounded, color: mc, size: 24)
                  : SizedBox(width: 24, child: Text('${i+1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isMe
                          ? const Color(0x99FFFFFF)
                          : Colors.grey.shade500))),
                title: Text(e.name, style: TextStyle(
                  fontFamily: 'Cormorant', fontSize: 17,
                  color: isMe ? Colors.white : Colors.black87,
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                trailing: Text('${e.score}', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold,
                  fontFamily: 'Aboreto',
                  color: isMe ? Colors.amber : kBurgundy))));
          });
      });
}
