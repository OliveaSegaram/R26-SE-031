import 'package:flutter/material.dart';

class PatternTrain extends StatelessWidget {
  final Widget locomotive;
  final List<Widget> carriages;

  const PatternTrain({
    Key? key,
    required this.locomotive,
    required this.carriages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Train Body
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              locomotive,
              ..._buildCoupledCarriages(),
            ],
          ),
        ),
        // Track Base Line (The wheels should sit right on top of this)
        Container(
          width: double.infinity,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF5A4D41), // track brown
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _RailwaySleepersPainter(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCoupledCarriages() {
    List<Widget> coupled = [];
    for (int i = 0; i < carriages.length; i++) {
      coupled.add(_buildCoupling());
      coupled.add(carriages[i]);
    }
    return coupled;
  }

  Widget _buildCoupling() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Container(
        width: 12,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFF757575), // grey coupling
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _RailwaySleepersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3D3126) // darker wood color for sleepers
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const spacing = 15.0;
    for (double i = 5; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
