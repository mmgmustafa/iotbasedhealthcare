import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SensorChart extends StatelessWidget {
  final List<FlSpot> lineData;
  final List<BarChartGroupData> barData;
  final String title;
  final bool isLineChart;

  const SensorChart({
    super.key,
    required this.lineData,
    required this.barData,
    required this.title,
    this.isLineChart = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.tealAccent),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: isLineChart
                  ? LineChart(LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineData,
                          isCurved: true,
                          color: Colors.tealAccent,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(show: false),
                    ))
                  : BarChart(BarChartData(
                      barGroups: barData,
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(show: false),
                    )),
            ),
          ],
        ),
      ),
    );
  }
}
