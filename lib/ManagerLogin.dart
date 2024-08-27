import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/DashboardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerLogin extends StatefulWidget {
  @override
  _ManagerLoginState createState() => _ManagerLoginState();
}

class _ManagerLoginState extends State<ManagerLogin> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://raihanmiraj.com/api/?managerlogin'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: json.encode({
            'username': _username,
            'password': _password,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['token'] != null) {
            // Save token and user data in SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('authToken', responseData['token']);
            await prefs.setString('managerName', responseData['managersname']);
            await prefs.setString('managerEmail', responseData['email']);

            // Navigate to the WelcomeScreen with the username
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(),
              ),
            );
          } else {
            _showErrorSnackBar('Invalid username or password');
          }
        } else {
          _showErrorSnackBar('Failed to login. Please try again.');
        }
      } catch (error) {
        _showErrorSnackBar('An error occurred. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manager Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
                onSaved: (value) {
                  _username = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
