import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/Account.dart';
import 'package:mealapp/CreateMealDay.dart';
import 'package:mealapp/GetAllPayments.dart';
import 'package:mealapp/GetSpents.dart';
import 'package:mealapp/GetStudents.dart';
import 'package:mealapp/InsertMeal.dart';
import 'package:mealapp/LoginScreen.dart';
import 'package:mealapp/PeopleScreen.dart';
import 'package:mealapp/PrintSheetScreen.dart';
import 'package:mealapp/SpentsEntry.dart';
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  
  // Variable to store the selected index
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardData = fetchDashboardData();
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}?getstatus'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard',style: TextStyle(color: Colors.black),),
        backgroundColor:const Color.fromARGB(255, 148, 227, 249),
        shadowColor: Colors.lightBlueAccent[100],
        elevation: 4,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 148, 227, 249),
              ),
              child: Image.asset(
                'Assets/meclogo.png', // Replace with your logo path
                height: 120,
                width: 120,
              ),
              
            ),

            _buildDrawerItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
            ),
            _buildDrawerItem(
              index: 1,
              icon: Icons.food_bank_rounded,
              title: 'Meal List',
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PeopleScreen()),
                );
              },
            ),
            _buildDrawerItem(
              index: 2,
              icon: Icons.insert_comment,
              title: 'Insert Spents',
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InsertSpentsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              index: 3,
              icon: Icons.get_app,
              title: 'Get Spent',
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GetSpentsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              index: 4,
              icon: Icons.print_sharp,
              title: 'Print Sheet',
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectDateScreen()),
                );
              },
            ),_buildDrawerItem(
              index: 5,
              icon: Icons.people_alt_outlined,
              title: 'Students',
              onTap: () {
                setState(() {
                  _selectedIndex = 5;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              index: 6,
              icon: Icons.payment,
              title: 'Payment',
              onTap: () {
                setState(() {
                  _selectedIndex = 6;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentScreen()),
                );
              },
            ),
            _buildDrawerItem(
              index: 7,
              icon: Icons.add_box_outlined,
              title: 'Insert Meals',
              onTap: () {
                setState(() {
                  _selectedIndex = 7;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InsertMealScreen()),
                );
              },
            ),
            _buildDrawerItem(
              index: 8,
              icon: Icons.account_balance_wallet,
              title: 'Accounts',
              onTap: () {
                setState(() {
                  _selectedIndex = 8;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountPage()),
                );
              },
            ),
            _buildDrawerItem(
              index: 9,
              icon: Icons.medication_liquid_rounded,
              title: 'Meal Day',
              onTap: () {
                setState(() {
                  _selectedIndex = 9;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateMealDayScreen()),
                );
              },
            ),
            // Add more items here with the same structure...
            _buildDrawerItem(
              index: 10,
              icon: Icons.settings_power_outlined,
              title: 'Log out',
              onTap: () async {
                setState(() {
                  _selectedIndex = 10;
                });
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      //       ListTile(
      //         leading: Icon(Icons.dashboard_outlined,),
      //         title: Text('Dashboard'),
      //         onTap: () {
      //           Navigator.pushReplacement(
      //             context,
      //             MaterialPageRoute(builder: (context) => DashboardScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.food_bank_rounded),
      //         title: Text('Meal List'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => PeopleScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.insert_comment),
      //         title: Text('Insert Spents'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => InsertSpentsScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.get_app),
      //         title: Text('Get Spents'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => GetSpentsScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.print_sharp),
      //         title: Text('Print Sheets'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => SelectDateScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.people_alt_rounded),
      //         title: Text('Students'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => StudentsScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.payment),
      //         title: Text('Payments'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => PaymentScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.add_box_outlined),
      //         title: Text('Insert Meals'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => InsertMealScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.account_balance_wallet),
      //         title: Text('Account'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => AccountPage()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.medication_liquid_rounded),
      //         title: Text('Meal Day'),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => CreateMealDayScreen()),
      //           );
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.settings_power_outlined),
      //         title: Text('Log out'),
      //         onTap: () async{
      //           Navigator.pushNamedAndRemoveUntil(context, '/login', (route)=>false);
      //         },
      //       )
      //     ],
      //   ),
      // ),
      body: Container(
        color: const Color.fromARGB(255, 208, 239, 255),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: GFLoader(type: GFLoaderType.circle
              ,));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No data available'));
            } else {
              final data = snapshot.data!;
              final totalReceivePayment = data['totalreceivepayment'];
              final totalSpent = data['totalspent'];
              final totalMeal = data['totalmeal'];
              final mealRate = data['mealrate'];
              final handCash = data['handcash'];
              final allMealStatus = data['allmealstatus'] as List<dynamic>;
        
              return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Summary',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            
                            _buildSummaryCard([
                              {'title': 'Total Received Payment', 'value': totalReceivePayment},
                              {'title': 'Total Spent', 'value': totalSpent},
                              {'title': 'Total Meal', 'value': totalMeal},
                              {'title': 'Meal Rate', 'value': mealRate},
                              {'title': 'Hand Cash', 'value': handCash},
                            ]),
                            SizedBox(height: 15),
                            Text(
                              'Meal Status Over Time',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: _buildMealStatusList(allMealStatus),
                            ),
                          ],
                        ),
                      );
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         'Financial Summary',
              //         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              //       ),
              //       SizedBox(height: 10),
              //       _buildSummaryCard('Total Received Payment', totalReceivePayment),
              //       _buildSummaryCard('Total Spent', totalSpent),
              //       _buildSummaryCard('Total Meal', totalMeal),
              //       _buildSummaryCard('Meal Rate', mealRate),
              //       _buildSummaryCard('Hand Cash', handCash),
              //       SizedBox(height: 20),
              //       Text(
              //         'Meal Status Over Time',
              //         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              //       ),
              //       SizedBox(height: 20),
              //       Expanded(
              //         child: _buildMealStatusList(allMealStatus),
              //       ),
              //     ],
              //   ),
              // );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Map<String, dynamic>> data) {
  return Card(
    elevation: 4,
    margin: EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.map((item) {
          String title = item['title'];
          dynamic value = item['value'];
          String displayValue;

          // Print debug information
          print('Title: $title');
          print('Value: $value');
          print('Type of value: ${value.runtimeType}');

          try {
            if (value is double) {
              // If value is a double, format it
              displayValue = value.toStringAsFixed(2);
            } else if (value is String) {
              // If value is a string, try to parse it to double
              double? parsedValue = double.tryParse(value);
              if (parsedValue != null) {
                displayValue = parsedValue.toStringAsFixed(2);
              } else {
                displayValue = value;
              }
            } else {
              // Handle other types or default to string conversion
              displayValue = value.toString();
            }
          } catch (e) {
            displayValue = 'Error: $e';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.black45),
                ),
                Text(
                  displayValue,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}

  // Widget _buildSummaryCard(String title, dynamic value) {
  //   String displayValue;

  //   // Print debug information
  //   print('Title: $title');
  //   print('Value: $value');
  //   print('Type of value: ${value.runtimeType}');

  //   try {
  //     if (value is double) {
  //       // If value is a double, format it
  //       displayValue = value.toStringAsFixed(2);
  //     } else if (value is String) {
  //       // If value is a string, try to parse it to double
  //       double? parsedValue = double.tryParse(value);
  //       if (parsedValue != null) {
  //         displayValue = parsedValue.toStringAsFixed(2);
  //       } else {
  //         displayValue = value;
  //       }
  //     } else {
  //       // Handle other types or default to string conversion
  //       displayValue = value.toString();
  //     }
  //   } catch (e) {
  //     displayValue = 'Error: $e';
  //   }

  //   return Card(
  //     elevation: 4,
  //     margin: EdgeInsets.symmetric(vertical: 8),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             title,
  //             style: TextStyle(fontSize: 18),
  //           ),
  //           Text(
  //             displayValue,
  //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMealStatusList(List<dynamic> allMealStatus) {
    return ListView.builder(
      itemCount: allMealStatus.length,
      itemBuilder: (context, index) {
        final mealStatus = allMealStatus[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              'Date: ${mealStatus['date']}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Total Meals: ${mealStatus['totalmeal']}',
              style: TextStyle(fontSize: 14),
            ),
            contentPadding: EdgeInsets.all(16),
          ),
        );
      },
    );
  }
}

 // Method to build each drawer item with index-based selection
  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String title,
    required Function() onTap,
  }) {
    
    var _selectedIndex;
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.black, // Change color when selected
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black, // Change text color when selected
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

void main() {
  runApp(MaterialApp(
    home: DashboardScreen(),
    routes: {
      '/dashboard': (context) => DashboardScreen(),
      '/people': (context) => PeopleScreen(),
      '/insertspents': (context) => InsertSpentsScreen(),
      '/get-spents': (context) => GetSpentsScreen(),
      '/print-sheets': (context) => SelectDateScreen(),
      '/get-students': (context) => StudentsScreen(),
      '/get-allpayments': (context) => PaymentScreen(),
      '/insert-meals': (context) => InsertMealScreen(),
      '/add_mealday': (context) => CreateMealDayScreen(),
      '/login': (context) => LoginScreen(),
    },
  ));
}
