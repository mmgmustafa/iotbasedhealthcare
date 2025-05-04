import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  Map<String, dynamic> latestData = {};
  Map<String, dynamic> additionalData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      await Future.wait([
        fetchLatestSensorData(),
        fetchAdditionalData(),
      ]);
    } catch (e) {
      print('❌ Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchLatestSensorData() async {
    try {
      final ref = FirebaseDatabase.instance.ref('sesnor_readings');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          final readings = Map<String, dynamic>.from(data);
          final latestTimestamp = readings.keys
              .map((e) => int.tryParse(e) ?? 0)
              .reduce((a, b) => a > b ? a : b)
              .toString();

          final latest = Map<String, dynamic>.from(readings[latestTimestamp]);

          print('✅ Latest data: $latest');

          setState(() {
            latestData = latest;
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching latest data: $e');
    }
  }

  Future<void> fetchAdditionalData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://iot-based-healthcare-sys-e8194-default-rtdb.firebaseio.com/sesnor_readings.json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          print('✅ Additional data fetched: $data');
          setState(() {
            additionalData = Map<String, dynamic>.from(data);
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching additional data: $e');
    }
  }

  Widget buildDataTile(String title, dynamic value, String unit) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
            value != null ? '$value $unit' : 'N/A',
            style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.tealAccent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                children: [
                  if (latestData.isNotEmpty) ...[
                    buildSectionTitle('Primary Sensor Data'),
                    buildDataTile(
                        'Heart Rate', latestData['heart_rate'], 'BPM'),
                    buildDataTile('SpO₂', latestData['spo2'], '%'),
                    buildDataTile(
                        'Temperature', latestData['temperature'], '°C'),
                    buildDataTile('Humidity', latestData['humidity'], '%'),
                    buildDataTile('EMG Signal', latestData['emg'], 'mV'),
                    buildDataTile('ECG Signal', latestData['ecg'], 'mV'),
                  ],
                  if (additionalData.isNotEmpty) ...[
                    buildSectionTitle('Additional Sensor Data'),
                    ...additionalData.entries.map((entry) {
                      final id = entry.key;
                      final data = Map<String, dynamic>.from(entry.value);
                      return Column(
                        children: data.entries.map((dataEntry) {
                          return buildDataTile(
                              '${dataEntry.key} ($id)',
                              dataEntry.value,
                              getUnitForMeasurement(dataEntry.key));
                        }).toList(),
                      );
                    }),
                  ],
                  if (latestData.isEmpty && additionalData.isEmpty)
                    const Center(
                      child: Text('No data found',
                          style: TextStyle(color: Colors.white)),)
                ],
              ),
            ),
    );
  }

  String getUnitForMeasurement(String measurement) {
    switch (measurement) {
      case 'heart_rate':
        return 'BPM';
      case 'spo2':
        return '%';
      case 'temperature':
        return '°C';
      case 'humidity':
        return '%';
      case 'emg':
        return 'mV';
      case 'ecg':
        return 'mV';
      default:
        return '';
    }
  }
}