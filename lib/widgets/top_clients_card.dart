import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/models/client.dart';

class TopClientsCard extends StatelessWidget {
  final List<Client>? clients;

  const TopClientsCard({super.key, this.clients});

  @override
  Widget build(BuildContext context) {
    // Calcular datos reales si hay clientes
    List<Map<String, dynamic>> clientData = [];
    if (clients != null && clients!.isNotEmpty) {
      // Tomar top 3 clientes por número de ventas
      final sortedClients = List<Client>.from(clients!);
      sortedClients.sort((a, b) => b.salesCount.compareTo(a.salesCount));
      final topClients = sortedClients.take(3).toList();
      
      final totalSales = topClients.fold<int>(0, (sum, client) => sum + client.salesCount);
      
      if (totalSales > 0) {
        clientData = topClients.map((client) {
          final percentage = (client.salesCount / totalSales * 100).round();
          return {
            'name': client.companyName ?? client.fullName,
            'percentage': percentage,
            'sales': client.salesCount,
          };
        }).toList();
      }
    }

    // Si no hay datos, usar datos de ejemplo
    if (clientData.isEmpty) {
      clientData = [
        {'name': 'No clients yet', 'percentage': 0, 'sales': 0},
      ];
    }

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
                  painter: DonutChartPainter(clientData: clientData),
                ),
              ),
              const SizedBox(width: 24),
              // Legends
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: clientData.isEmpty
                      ? [
                          const Text(
                            'No data',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                            ),
                          ),
                        ]
                      : clientData.take(3).map((data) {
                          final index = clientData.indexOf(data);
                          final colors = [
                            const Color(0xFF5B4FB8),
                            const Color(0xFF8DD4C3),
                            AppColors.white,
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildLegend(
                              '${data['percentage']}%',
                              data['name'] as String,
                              colors[index % colors.length],
                            ),
                          );
                        }).toList(),
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
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color == AppColors.white ? AppColors.textPrimary : AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> clientData;

  DonutChartPainter({required this.clientData});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 25.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (clientData.isEmpty || clientData[0]['percentage'] == 0) {
      // Círculo vacío
      paint.color = const Color(0xFF8DD4C3);
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    // Colores para los segmentos
    final colors = [
      const Color(0xFF5B4FB8),
      const Color(0xFF8DD4C3),
      const Color(0xFFB8E6D9),
    ];

    double startAngle = -math.pi / 2;
    
    for (int i = 0; i < clientData.length && i < 3; i++) {
      final percentage = (clientData[i]['percentage'] as int) / 100.0;
      final sweepAngle = 2 * math.pi * percentage;

      paint.color = colors[i % colors.length];
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Relleno para el resto del círculo
    if (startAngle < -math.pi / 2 + 2 * math.pi) {
      paint.color = const Color(0xFF8DD4C3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        -math.pi / 2 + 2 * math.pi - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
