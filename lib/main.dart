import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/loading.dart';
import 'services/music_service.dart';
import 'l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform);
  await AppLocale().load();
  MusicService().init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const MahjongApp());
}

class MahjongApp extends StatefulWidget {
  const MahjongApp({super.key});
  @override State<MahjongApp> createState() => _State();
}

class _State extends State<MahjongApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLocale().addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Останавливаем музыку когда телефон уходит в фон/выключается
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      MusicService().pause();
    } else if (state == AppLifecycleState.resumed) {
      // Возобновляем только если музыка была включена пользователем
      if (MusicService().isOn) MusicService().resume();
    }
  }

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  );
}