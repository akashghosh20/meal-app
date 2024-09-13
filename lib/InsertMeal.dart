import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsertMealScreen extends StatefulWidget {
  @override
  _InsertMealScreenState createState() => _InsertMealScreenState();
}

class _InsertMealScreenState extends State<InsertMealScreen> {
  String? _selectedStudent;
  DateTime _selectedDate = DateTime.now();
  int _status = 0;
  String _mealType = 'Full Meal'; // Default to Full Meal
  bool _isLoading = false;
  String _message = '';
  List<dynamic> _students = [];
  String? _selectedHallId;
  String? _mealDayId;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}?students'),
        headers: {
          'Authorization': '$token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _students = json.decode(response.body);
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
    }
  }

  Future<void> _submitMeal() async {
    if (_selectedStudent == null) {
      setState(() {
        _message = 'Please select a student';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    // Get the student details for hallId and calculate mealDayId
    final selectedStudent = _students.firstWhere((student) => student['id'].toString() == _selectedStudent);
    _selectedHallId = selectedStudent['hallid'];
    _mealDayId = DateFormat('yyyyMMdd').format(_selectedDate); // Assuming mealDayId is based on date

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}?insertnewmeal'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'studentid': _selectedStudent,
          'type': _mealType == 'Lunch' ? '1' : '2', // Assuming '1' for Lunch and '2' for Full Meal
          'hallid': _selectedHallId,
          'status': _status.toString(),
          'mealdayid': _mealDayId,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        setState(() {
          _message = 'Meal inserted successfully';
        });
      } else {
        setState(() {
          _message = 'Failed to insert meal: ${responseData['message'] ?? 'Unknown error'}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insert Meal'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Searchable Dropdown
                  DropdownSearch<dynamic>(
                    items: _students,
                    itemAsString: (item) => item['name'] ?? '',
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Select Student',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    popupProps: PopupProps.dialog(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                        ),
                      ),
                    ),
                    onChanged: (selectedItem) {
                      if (selectedItem != null) {
                        setState(() {
                          _selectedStudent = selectedItem['id'].toString();
                          _selectedHallId = selectedItem['hallid'];
                        });
                      }
                    },
                    selectedItem: _students.isNotEmpty
                        ? _students.firstWhere(
                            (student) => student['id'].toString() == _selectedStudent,
                            orElse: () => _students.first)
                        : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Select Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                          _mealDayId = DateFormat('yyyyMMdd').format(_selectedDate); // Update mealDayId
                        });
                      }
                    },
                    controller: TextEditingController(
                      text: DateFormat('yyyy-MM-dd').format(_selectedDate),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status: $_status', style: TextStyle(fontSize: 18)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (_status > 0) _status--;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _status++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _mealType,
                    hint: Text('Select Meal Type'),
                    items: ['Lunch', 'Full Meal'].map((mealType) {
                      return DropdownMenuItem<String>(
                        value: mealType,
                        child: Text(mealType),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _mealType = value!;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitMeal,
                      child: Text('Submit Meal'),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_message.isNotEmpty)
                    Center(
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: _message.contains('successfully') ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: InsertMealScreen(),
  ));
}
