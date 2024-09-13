import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentsScreen extends StatefulWidget {
  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = false;
  String _message = '';
  String _searchQuery = '';
  Timer? _debounce;  // Timer for debounce

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _debounce?.cancel();  // Dispose of the debounce timer when the widget is disposed
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/?students'),
        headers: {
          'Authorization': '$token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _students = json.decode(response.body);
          _filteredStudents = _students; // Initially, show all students
        });
      } else {
        setState(() {
          _message = 'Failed to fetch students';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    // Cancel the previous debounce timer and start a new one
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(Duration(milliseconds: 500), () {
      // Trigger the search after 500ms delay
      _filterStudents(query);
    });
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      _filteredStudents = _students.where((student) {
        final name = student['name']?.toLowerCase() ?? '';
        final hallId = student['hallid']?.toLowerCase() ?? '';
        final roomNo = student['roomno']?.toLowerCase() ?? '';
        final searchLower = query.toLowerCase();

        return name.contains(searchLower) ||
            hallId.contains(searchLower) ||
            roomNo.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, hall ID, or room number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged,  // Use debounce for search
                  ),
                ),
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? Center(
                          child: Text(
                            _message.isNotEmpty
                                ? _message
                                : 'No students found.',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.0),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(
                                  student['name'] ?? 'No Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (student['roomno'] != null)
                                      Text('Room No: ${student['roomno']}'),
                                    if (student['email'] != null)
                                      Text('Email: ${student['email']}'),
                                    if (student['phone'] != null)
                                      Text('Phone: ${student['phone']}'),
                                    if (student['bloodgroup'] != null)
                                      Text(
                                          'Blood Group: ${student['bloodgroup']}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}


