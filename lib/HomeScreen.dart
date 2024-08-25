import 'dart:convert';

import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ManagerDetailScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _managerLists;
  int _selectedIndex = 0;

  String? name;
  String? username;
  String? email;
  String? role;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _managerLists = fetchManagerLists();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
      username = prefs.getString('username');
      email = prefs.getString('email');
      role = prefs.getString('role');
    });
  }

  Future<List<Map<String, dynamic>>> fetchManagerLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Authentication token is missing');
    }

    final response = await http.get(
      Uri.parse('https://raihanmiraj.com/api/?managers'),
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load manager lists');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Handle navigation based on the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null) Text(name!),
            if (role != null) Text('Role: $role'),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _managerLists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            final managers = snapshot.data!;

            return ListView.builder(
              itemCount: managers.length,
              itemBuilder: (context, index) {
                final manager = managers[index];
                return ListTile(
                  title: Text(manager['managersname']),
                  subtitle: Text(manager['email']),
                  leading: Icon(Icons.person),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManagerDetailScreen(managerId: manager['id']),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        onTap: _onTabTapped,
        items: <CurvedNavigationBarItem>[
          CurvedNavigationBarItem(
            child: Icon(Icons.home, size: 30),
            label: 'Home',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.search, size: 30),
            label: 'Search',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.person, size: 30),
            label: 'Profile',
          ),
        ],
        color: Colors.blue,
        backgroundColor: Colors.white,
        height: 60.0,
      ),
    );
  }
}
