import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
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
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Aboreto',
            fontSize: 38,
            color: burgundy,
          ),
        ),
      ),
///ФОН
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/profile.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
