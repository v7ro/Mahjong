import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final String imagePath;
  
  const Background({
    required this.child, 
    required this.imagePath, 
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}