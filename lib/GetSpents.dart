import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetSpentsScreen extends StatefulWidget {
  @override
  _GetSpentsScreenState createState() => _GetSpentsScreenState();
}

class _GetSpentsScreenState extends State<GetSpentsScreen> {
  late Future<List<dynamic>> _spentsData;

  @override
  void initState() {
    super.initState();
    _spentsData = fetchSpentsData();
  }

  Future<List<dynamic>> fetchSpentsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}?getspents'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load spents data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spents Data'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _spentsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            final spents = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: spents.length,
                itemBuilder: (context, index) {
                  final spent = spents[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'Amount: \$${spent['amount']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${spent['date']}', style: TextStyle(fontSize: 16)),
                          Text('Note: ${spent['note']}', style: TextStyle(fontSize: 16)),
                          Text('Created At: ${spent['created_at']}', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
