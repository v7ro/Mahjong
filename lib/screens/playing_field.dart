import 'package:flutter/material.dart';
import 'setting.dart';

class PlayingFieldScreen extends StatelessWidget {
  const PlayingFieldScreen({super.key});
  static const Color black = Color(0xFF454545);
  static const Color burgundy = Color(0xFF6B1F2B);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    extendBodyBehindAppBar: true,  
    appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: burgundy),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/playing_field.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
/// SETTINGS
          Positioned(
            left: 307,
            top: 44,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingScreen(),
                  ),
                );
              },
              child: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/setting.PNG'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x66454545),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x33FFFFFF),
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
}
