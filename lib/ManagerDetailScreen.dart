import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ManagerDetailScreen extends StatefulWidget {
  final String managerId;

  ManagerDetailScreen({required this.managerId});

  @override
  _ManagerDetailScreenState createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends State<ManagerDetailScreen> {
  late Future<Map<String, dynamic>> _mealData;

  @override
  void initState() {
    super.initState();
    _mealData = fetchMealData();
  }

  Future<Map<String, dynamic>> fetchMealData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Authentication token is missing');
    }

    final response = await http.get(
      Uri.parse('https://raihanmiraj.com/api/?getmealofmanager=${widget.managerId}'),
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load meal data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _mealData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No data available'));
          } else {
            final mealData = snapshot.data!;
            
            // Extract date keys, excluding non-date fields
            final dateKeys = mealData.keys.where((key) {
              final regex = RegExp(r'\d{4}-\d{2}-\d{2}');
              return regex.hasMatch(key);
            }).toList();

            return ListView(
              padding: EdgeInsets.all(16.0),
              children: <Widget>[
                Text('Name: ${mealData['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Room No: ${mealData['roomno']}', style: TextStyle(fontSize: 16)),
                Text('Manager Name: ${mealData['managername']}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Text('Meal Dates:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...dateKeys.map((date) {
                  return ListTile(
                    title: Text(date),
                    trailing: Text(mealData[date] == "1" ? "Meal Assigned" : "No Meal"),
                  );
                }).toList(),
              ],
            );
          }
        },
      ),
    );
  }
}
