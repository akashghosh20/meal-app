import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateMealDayScreen extends StatefulWidget {
  @override
  _CreateMealDayScreenState createState() => _CreateMealDayScreenState();
}

class _CreateMealDayScreenState extends State<CreateMealDayScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCopyDateId;
  String? _authToken;
  List<Map<String, dynamic>> _mealDays = []; // Store meal days from the API

  @override
  void initState() {
    super.initState();
    print('initState called');
    _loadToken().then((_) {
      _fetchMealDays(); // Ensure this is called after the token is loaded
    });
  }

  // Function to load the token from SharedPreferences
  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('authToken');
    });
    print('Token loaded: $_authToken');
  }

  // Function to fetch meal days from the API
Future<void> _fetchMealDays() async {
  print('fetchMealDays called');
  if (_authToken != null) {
    print('Token is not null, proceeding with API call');
    final response = await http.get(
      Uri.parse('${Config.baseUrl}?getmealday'),
      headers: {
        'Authorization': '$_authToken',
      },
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Response data: $responseData');

      if (responseData is List) {
        setState(() {
          _mealDays = List<Map<String, dynamic>>.from(responseData);
          print('Meal days updated: $_mealDays');
        });
      } else {
        print('Unexpected response format: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected response format')),
        );
      }
    } else {
      print('Error: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.statusCode}')),
      );
    }
  } else {
    print('Auth token is null, skipping API call');
  }
}


  // Function to handle date selection
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to submit the form data
  Future<void> _submitForm() async {
  if (_formKey.currentState!.validate() && _authToken != null && _selectedCopyDateId != null) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Prepare the request body in JSON format
    final requestBody = jsonEncode({
      'date': formattedDate,
      'copydate': _selectedCopyDateId, // Send the selected copy date ID
    });

    // API request with the token
    final response = await http.post(
      Uri.parse('https://raihanmiraj.com/api/?createmealday'),
      headers: {
        'Authorization': '$_authToken', // Include the token in the header
        'Content-Type': 'application/json', // Specify that the request body is JSON
      },
      body: requestBody, // Pass the JSON-encoded body
    );

    print('Request body: $requestBody');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Response data: $responseData');

      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meal day created successfully!')),
        );
      } else {
        print('Meal day creation failed: ${responseData['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create meal day: ${responseData['message']}')),
        );
      }
    } else {
      print('Error: ${response.statusCode} - ${response.reasonPhrase}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.statusCode} - ${response.reasonPhrase}')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Token not found, form validation failed, or copy date not selected!')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Meal Day', style: TextStyle(color: Colors.black),),
        backgroundColor:const Color.fromARGB(255, 148, 227, 249),
        shadowColor: Colors.lightBlueAccent[100],
        elevation: 4,
      ),
      body: Container(
        color: const Color.fromARGB(255, 208, 239, 255),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Picker for the main date
                ListTile(
                  title: Text('Select Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}', style: TextStyle(fontWeight: FontWeight.bold),),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                SizedBox(height: 20),
        
                // Dropdown for the copy date
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Select Copy Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                      color: Colors.orange,
                      width: 5
                      )
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                      color: Colors.green, // Border color when focused
                      width: 2.0,
                      ),
                    ),
                  ),
                  value: _selectedCopyDateId,
                  items: _mealDays.map((mealDay) {
                    return DropdownMenuItem<String>(
                      value: mealDay['id'].toString(), // Use the id as the value
                      child: Text(mealDay['date']), // Display the date in the dropdown
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCopyDateId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a copy date' : null,
                ),
                SizedBox(height: 20),
        
                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Create Meal Day', style: TextStyle(color: Colors.white, fontSize: 15), ),
                  style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 148, 227, 249), // Updated parameter
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
