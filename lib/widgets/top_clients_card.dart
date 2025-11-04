import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:veon_app/screens/auth/constants/colors.dart';

class TopClientsCard extends StatelessWidget {
  const TopClientsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Clients',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: DonutChartPainter(),
                ),
              ),
              const SizedBox(width: 24),
              // Legends
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegend('60%', 'Walmart', const Color(0xFF5B4FB8)),
                    const SizedBox(height: 8),
                    _buildLegend('40%', 'El Zorro', const Color(0xFF8DD4C3)),
                    const SizedBox(height: 8),
                    _buildLegend('20%', 'Externos', AppColors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String percentage, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            percentage,
            style: TextStyle(
              color: color == AppColors.white ? AppColors.textPrimary : AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: color == AppColors.white ? AppColors.textPrimary : AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 25.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background circle
    paint.color = const Color(0xFF8DD4C3);
    canvas.drawCircle(center, radius - strokeWidth / 2, paint);

    // Purple segment (60% = 216 degrees)
    paint.color = const Color(0xFF5B4FB8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * 0.6,
      false,
      paint,
    );

    // Light green segment (40% = 144 degrees)
    paint.color = const Color(0xFFB8E6D9);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2 + 2 * math.pi * 0.6,
      2 * math.pi * 0.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}