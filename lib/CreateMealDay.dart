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
  DateTime _selectedCopyDate = DateTime.now();
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  // Function to load the token from SharedPreferences
  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('authToken');
    });
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

  // Function to handle copy date selection
  Future<void> _selectCopyDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedCopyDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedCopyDate) {
      setState(() {
        _selectedCopyDate = picked;
      });
    }
  }

  // Function to submit the form data
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _authToken != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final formattedCopyDate = DateFormat('yyyy-MM-dd').format(_selectedCopyDate);

      // API request with the token
      final response = await http.post(
        Uri.parse('${Config.baseUrl}?createmealday'),
        headers: {
          'Authorization': '$_authToken', // Include the token in the header
        },
        body: {
          'date': formattedDate,
          'copydate': formattedCopyDate,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Meal day created successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create meal day!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token not found or form validation failed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Meal Day'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Picker for the main date
              ListTile(
                title: Text('Select Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 20),

              // Date Picker for the copy date
              ListTile(
                title: Text('Select Copy Date: ${DateFormat('yyyy-MM-dd').format(_selectedCopyDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectCopyDate(context),
              ),
              SizedBox(height: 40),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Create Meal Day'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
