import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PeopleScreen extends StatefulWidget {
  @override
  _PeopleScreenState createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late Future<List<dynamic>> _peopleData;
  List<dynamic> _filteredPeople = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _peopleData = fetchPeopleData();
  }

  Future<List<dynamic>> fetchPeopleData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('https://raihanmiraj.com/api/?all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load people data');
    }
  }

  void _filterPeople(List<dynamic> people) {
    setState(() {
      _filteredPeople = people.where((person) {
        final nameLower = person['name'].toLowerCase();
        final hallLower = person['hallid'].toString().toLowerCase();
        final roomLower = person['roomno'].toString().toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        return nameLower.contains(searchLower) ||
            hallLower.contains(searchLower) ||
            roomLower.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('People List'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _peopleData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            final people = snapshot.data!;
            if (_filteredPeople.isEmpty && _searchQuery.isEmpty) {
              _filteredPeople = people;
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GFSearchBar(
                    searchList: people,
                    searchQueryBuilder: (query, list) {
                      setState(() {
                        _searchQuery = query;
                      });
                      _filterPeople(people);
                      return _filteredPeople.map((item) => item['name']).toList();
                    },
                    overlaySearchListItemBuilder: (dynamic item) => Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    onItemSelected: (dynamic item) {
                      final selectedPerson = people.firstWhere((person) => person['name'] == item);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonDetailsScreen(person: selectedPerson),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredPeople.length,
                    itemBuilder: (context, index) {
                      final person = _filteredPeople[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            person['name'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Room: ${person['roomno']}\nPayment: ${person['payment']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PersonDetailsScreen(person: person),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class PersonDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> person;

  const PersonDetailsScreen({Key? key, required this.person}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mealDates = person.keys.where((key) => key != 'id' && key != 'roomno' && key != 'name' && key != 'hallid' && key != 'managerid' && key != 'payment').toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Details for ${person['name']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Number: ${person['roomno']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Payment: ${person['payment']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Meal Status Over Time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: mealDates.length,
                itemBuilder: (context, index) {
                  final date = mealDates[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        'Date: $date',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Meals: ${person[date]}',
                        style: TextStyle(fontSize: 14),
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}