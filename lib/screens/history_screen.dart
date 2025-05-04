import '../widgets/sensor_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic> allData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllSensorData();
  }

  Future<void> fetchAllSensorData() async {
    try {
      final ref = FirebaseDatabase.instance.ref('sensor_readings');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          setState(() {
            allData = Map<String, dynamic>.from(data);
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() => isLoading = false);
    }
  }

  List<FlSpot> generateLineData(String key) {
    final sortedKeys = allData.keys.toList()..sort();
    List<FlSpot> spots = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      final data = Map<String, dynamic>.from(allData[sortedKeys[i]]);
      final value = double.tryParse(data[key]?.toString() ?? '');
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    return spots;
  }

  List<BarChartGroupData> generateBarData(String key) {
    final sortedKeys = allData.keys.toList()..sort();
    List<BarChartGroupData> bars = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      final data = Map<String, dynamic>.from(allData[sortedKeys[i]]);
      final value = double.tryParse(data[key]?.toString() ?? '');
      if (value != null) {
        bars.add(BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: Colors.tealAccent,
              width: 12,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ));
      }
    }
    return bars;
  }

  Widget buildChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          height: 200,
          child: chart,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildDataTile(String timestamp, Map<String, dynamic> data) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timestamp: $timestamp',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('❤️ Heart: ${data['heart_rate'] ?? 'N/A'} BPM',
                    style: const TextStyle(color: Colors.white)),
                Text('🩸 SpO₂: ${data['spo2'] ?? 'N/A'}%',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🌡️ Temp: ${data['temperature'] ?? 'N/A'}°C',
                    style: const TextStyle(color: Colors.white)),
                Text('💧 Hum: ${data['humidity'] ?? 'N/A'}%',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 6),
            if (data['emg'] != null)
              Text('⚡ EMG: ${data['emg']} mV',
                  style: const TextStyle(color: Colors.white)),
            if (data['ecg'] != null)
              Text('📈 ECG: ${data['ecg']} mV',
                  style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAllSensorData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : allData.isEmpty
              ? const Center(
                  child: Text('No data found',
                      style: TextStyle(color: Colors.white)),
                )
              : ListView(
                  children: [
                    // Graph Sections
                    buildChartSection(
                      "Heart Rate (BPM)",
                      LineChart(LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: generateLineData("heart_rate"),
                            isCurved: true,
                            color: Colors.redAccent,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      )),
                    ),
                    buildChartSection(
                      "SpO₂ (%)",
                      BarChart(BarChartData(
                        barGroups: generateBarData("spo2"),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      )),
                    ),
                    buildChartSection(
                      "Temperature (°C)",
                      LineChart(LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: generateLineData("temperature"),
                            isCurved: true,
                            color: Colors.orangeAccent,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      )),
                    ),
                    buildChartSection(
                      "Humidity (%)",
                      BarChart(BarChartData(
                        barGroups: generateBarData("humidity"),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      )),
                    ),

                    // Divider
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Divider(color: Colors.tealAccent),
                    ),

                    // Data Entries
                    ...allData.entries.map((entry) {
                      final timestamp = entry.key;
                      final data = Map<String, dynamic>.from(entry.value);
                      return buildDataTile(timestamp, data);
                    }).toList(),
                  ],
                ),
    );
  }
}
