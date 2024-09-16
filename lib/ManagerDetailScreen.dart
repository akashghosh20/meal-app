import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerDetailScreen extends StatefulWidget {
  final String managerId;

  ManagerDetailScreen({required this.managerId});

  @override
  _ManagerDetailScreenState createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends State<ManagerDetailScreen> {
  late Future<Map<String, dynamic>> _mealData;
  bool canUpdateMeal = false;

  @override
  void initState() {
    super.initState();
    _mealData = fetchMealData();
  }

  Future<Map<String, dynamic>> fetchMealData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('AuthToken');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}?getmealofmanager=${widget.managerId}'),
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        canUpdateMeal = data['success'] == true;
      });

      return data;
    } else {
      throw Exception('Failed to load meal data');
    }
  }

  Future<void> updateMealCount(String date, int newMealCount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('AuthToken');

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}?insertmealfromuser'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'date': date,
          'status': newMealCount,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(responseData);

        if (responseData['success'] == true) {
          // Refresh data after successful update
         // await fetchMealData();
        } else {
          showErrorSnackBar('Failed to update meal count.');
        }
      } else {
        showErrorSnackBar('Failed to update meal count.');
      }
    } catch (e) {
      showErrorSnackBar('An error occurred while updating meal count.');
    }
  }

  void showErrorSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String formatMealCount(int mealCount) {
    if (mealCount == 1) {
      return 'ON';
    } else if (mealCount == 0) {
      return 'OFF';
    } else {
      return mealCount.toString();
    }
  }

  bool shouldAllowUpdate(String date) {
    DateTime mealDate = DateTime.parse(date);
    DateTime currentDate = DateTime.now();

    // Allow update if it's the next day or the status is true
    return canUpdateMeal || mealDate.isAfter(currentDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Details', style: TextStyle(color: Colors.black),),
        backgroundColor:const Color.fromARGB(255, 148, 227, 249),
        shadowColor: Colors.lightBlueAccent[100],
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _mealData = fetchMealData(); // Refresh data
              });
            },
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 208, 239, 255),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _mealData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: GFLoader(type: GFLoaderType.circle));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No data available'));
            } else {
              final mealData = snapshot.data!;
        
              // Extract date keys, excluding non-date fields
              final dateKeys = mealData.keys.where((key) {
                final regex = RegExp(r'\d{4}-\d{2}-\d{2}');
                return regex.hasMatch(key);
              }).toList();
        
              return ListView(
                padding: EdgeInsets.all(16.0),
                children: <Widget>[
                  Text('Name: ${mealData['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Room No: ${mealData['roomno']}', style: TextStyle(fontSize: 16)),
                  Text('Manager Name: ${mealData['managername']}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  Text('Meal Dates:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...dateKeys.map((date) {
                    int mealCount = int.tryParse(mealData[date]) ?? 0;
        
                    return ListTile(
                      title: Text(date),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (shouldAllowUpdate(date)) ...[
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () async {
                                if (mealCount > 0) {
                                  setState(() {
                                    mealCount--;
                                    mealData[date] = mealCount.toString();
                                  });
                                  await updateMealCount(date, mealCount);
                                }
                              },
                            ),
                          ],
                          Text(formatMealCount(mealCount)),
                          if (shouldAllowUpdate(date)) ...[
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () async {
                                setState(() {
                                  mealCount++;
                                  mealData[date] = mealCount.toString();
                                });
                                await updateMealCount(date, mealCount);
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
