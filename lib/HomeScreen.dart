import 'dart:convert';
import 'dart:io';

import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mealapp/EdituserProfile.dart';
import 'package:mealapp/ManagerDetailScreen.dart';
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Map<String, dynamic>>>? _managerLists;
  Future<Map<String, dynamic>>? _mealData;
  int _selectedIndex = 0;

  String? name;
  String? username;
  String? email;
  String? role;
  File? _image;
  String _message = ''; // Declare _message here
  String? _uploadedImageUrl; // Added this line

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _managerLists = fetchManagerLists();
    _mealData = fetchMealData();
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
    String? token = prefs.getString('AuthToken');

    if (token == null) {
      throw Exception('Authentication token is missing');
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}?managers'),
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

  Future<Map<String, dynamic>> fetchMealData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('AuthToken');

    if (token == null) {
      throw Exception('Authentication token is missing');
    }

    final response = await http.get(
      Uri.parse('${Config.baseUrl}?getmeal'),
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load meal data');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('AuthToken');

    if (token == null) {
      setState(() {
        _message = 'Auth token not found';
      });
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}?imageupload'),
      );
      request.headers['Authorization'] = '$token';

      // Add the image file with the key 'image'
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print(responseBody);

      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      final responseData = json.decode(responseBody);
      if (response.statusCode == 200 && responseData['success'] == true) {
        setState(() {
          _message = 'Image uploaded successfully';
          _uploadedImageUrl = responseData['image']; // Assuming API returns the URL of the uploaded image
        });
      } else {
        setState(() {
          _message = 'Failed to upload image: ${responseData['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildManagerList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _managerLists,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: GFLoader(type: GFLoaderType.circle));
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
                title: Text(manager['managersname'] ?? 'No Name'),
                subtitle: Text(manager['email'] ?? 'No Email'),
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
    );
  }

  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name != null) Text('Name: $name', style: TextStyle(fontSize: 18)),
          if (username != null) Text('Username: $username', style: TextStyle(fontSize: 18)),
          if (email != null) Text('Email: $email', style: TextStyle(fontSize: 18)),
          if (role != null) Text('Role: $role', style: TextStyle(fontSize: 18)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            },
            child: Text('Edit Profile'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick and Upload Image'),
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
          if (_uploadedImageUrl != null)  // Display the uploaded image if available
            Center(
              child: Image.network(_uploadedImageUrl!),
            ),
        ],
      ),
    );
  }

  Widget _buildMealData() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _mealData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: GFLoader(type: GFLoaderType.circle));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          final mealData = snapshot.data!;

          if (mealData.isNotEmpty) {
            return ListView(
              padding: EdgeInsets.all(16.0),
              children: <Widget>[
                Text('Name: ${mealData['name'] ?? 'N/A'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Room No: ${mealData['roomno'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
                Text('Manager Name: ${mealData['managername'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Text('Meal Dates:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...mealData.keys.where((key) {
                  final regex = RegExp(r'\d{4}-\d{2}-\d{2}');
                  return regex.hasMatch(key) && key != 'name' && key != 'roomno' && key != 'managername';
                }).map((date) {
                  int mealCount = int.tryParse(mealData[date]) ?? 0;

                  return ListTile(
                    title: Text(date),
                    trailing: Text(mealCount == 0 ? 'OFF' : mealCount == 1 ? 'ON' : mealCount.toString()),
                  );
                }).toList(),
              ],
            );
          } else {
            return Center(child: Text('Unexpected data format'));
          }
        }
      },
    );
  }

  Widget _getBodyWidget() {
    switch (_selectedIndex) {
      case 0:
        return _buildMealData();
      case 1:
        return _buildManagerList();
      case 2:
        return _buildProfile();
      default:
        return _buildMealData();
    }
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
      body: _getBodyWidget(),
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
            label: 'Managers',
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
