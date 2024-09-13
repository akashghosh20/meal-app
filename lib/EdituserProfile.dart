import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _username;
  String? _email;
  String? _phone;
  String? _bloodGroup;
  String? _password;
  String? _role;
  bool _isLoading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name');
      _username = prefs.getString('username');
      _email = prefs.getString('email');
      _phone = prefs.getString('phone');
      _bloodGroup = prefs.getString('bloodGroup');
      _role = prefs.getString('role');
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _message = '';
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('AuthToken');

    print('Auth Token: $token'); // For debugging

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}?updateprofile'),
        headers: {
          'Authorization': '$token', // Ensure Bearer is added
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _username,
          'email': _email,
          'phone': _phone,
          'blood_group': _bloodGroup,
          'password': _password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        setState(() {
          _message = 'Profile updated successfully';
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _message = 'Unauthorized. Please log in again.';
        });
      } else {
        setState(() {
          _message = 'Failed to update profile: ${responseData['message'] ?? 'Unknown error'}';
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
        title: Text('Edit Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: _username,
                        decoration: InputDecoration(labelText: 'Username'),
                        onSaved: (value) => _username = value,
                        validator: (value) => value!.isEmpty ? 'Please enter your username' : null,
                      ),
                      TextFormField(
                        initialValue: _email,
                        decoration: InputDecoration(labelText: 'Email'),
                        onSaved: (value) => _email = value,
                        validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                      ),
                      TextFormField(
                        initialValue: _phone,
                        decoration: InputDecoration(labelText: 'Phone'),
                        onSaved: (value) => _phone = value,
                        validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                      ),
                      TextFormField(
                        initialValue: _bloodGroup,
                        decoration: InputDecoration(labelText: 'Blood Group'),
                        onSaved: (value) => _bloodGroup = value,
                        validator: (value) => value!.isEmpty ? 'Please enter your blood group' : null,
                      ),
                      TextFormField(
                        initialValue: _password,
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        onSaved: (value) => _password = value,
                        validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                      ),
                     
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        child: Text('Update Profile'),
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
              ),
            ),
    );
  }
}
