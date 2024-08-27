import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/PeopleScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Import the PeopleScreen file

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = fetchDashboardData();
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('https://raihanmiraj.com/api/?getstatus'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Dashboard Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('People List'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PeopleScreen()),
                );
              },
            ),
            // Add more sidebar items here if needed
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No data available'));
          } else {
            final data = snapshot.data!;
            final totalReceivePayment = data['totalreceivepayment'];
            final totalSpent = data['totalspent'];
            final totalMeal = data['totalmeal'];
            final mealRate = data['mealrate'];
            final handCash = data['handcash'];
            final allMealStatus = data['allmealstatus'] as List<dynamic>;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Summary',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildSummaryCard('Total Received Payment', totalReceivePayment),
                  _buildSummaryCard('Total Spent', totalSpent),
                  _buildSummaryCard('Total Meal', totalMeal),
                  _buildSummaryCard('Meal Rate', mealRate.toStringAsFixed(2)),
                  _buildSummaryCard('Hand Cash', handCash.toString()),
                  SizedBox(height: 20),
                  Text(
                    'Meal Status Over Time',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: _buildMealStatusList(allMealStatus),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealStatusList(List<dynamic> allMealStatus) {
    return ListView.builder(
      itemCount: allMealStatus.length,
      itemBuilder: (context, index) {
        final mealStatus = allMealStatus[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              'Date: ${mealStatus['date']}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Total Meals: ${mealStatus['totalmeal']}',
              style: TextStyle(fontSize: 14),
            ),
            contentPadding: EdgeInsets.all(16),
          ),
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: DashboardScreen(),
    routes: {
      '/dashboard': (context) => DashboardScreen(),
      '/people': (context) => PeopleScreen(), // Register the new route
    },
  ));
}
