import 'package:flutter/material.dart';

class CurvedBackground extends StatelessWidget {
  final Widget child;
  final Color skyColor;
  final Color groundColor;

  const CurvedBackground({
    Key? key,
    required this.child,
    this.skyColor = const Color(0xFF1E4B5E),
    this.groundColor = const Color(0xFF0F8A8B),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: skyColor,
      child: Stack(
        children: [
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: groundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(250, 50),
                  topRight: Radius.elliptical(250, 50),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
