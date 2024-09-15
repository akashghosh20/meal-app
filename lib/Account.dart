import 'dart:async'; // Add this import for Timer
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  List<dynamic> mealData = [];
  List<dynamic> filteredMealData = [];
  String token = '';
  String searchQuery = '';
  Timer? _debounce; // Declare a Timer for debouncing

  @override
  void initState() {
    super.initState();
    fetchTokenAndMealData();
  }

  Future<void> fetchTokenAndMealData() async {
    // Get token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('authToken');

    setState(() {
      token = savedToken!;
    });
    fetchMealData(savedToken!);
    }

  Future<void> fetchMealData(String token) async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}?printlistsort=all'),
      headers: {
        'Authorization': '$token',  // Pass token in headers
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        mealData = json.decode(response.body);
        filteredMealData = mealData; // Initially, all data is displayed
      });
    } else {
      throw Exception('Failed to load meal data');
    }
  }

  // Method to filter meal data based on search query
  void filterSearchResults(String query) {
    List<dynamic> filteredList = [];
    if (query.isNotEmpty) {
      filteredList = mealData.where((meal) {
        return meal['name'].toLowerCase().contains(query.toLowerCase()) ||
               meal['roomno'].toString().contains(query);
      }).toList();
    } else {
      filteredList = mealData;
    }
    setState(() {
      filteredMealData = filteredList;
    });
  }

  // Debounce search input
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel(); // Cancel the previous timer if still running
    _debounce = Timer(const Duration(milliseconds: 300), () {
      filterSearchResults(query); // Call the search filter after 300ms
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel the debounce timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account', style: TextStyle(color: Colors.black),),
        backgroundColor:const Color.fromARGB(255, 148, 227, 249),
        shadowColor: Colors.lightBlueAccent[100],
        elevation: 4,
      ),
      body: Container(
        color: const Color.fromARGB(255, 208, 239, 255),
        child: Column(
          children: [
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: onSearchChanged, // Use the debounce method here
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Search by Name or Room No',
                  hintText: 'Enter Name or Room Number',
                  prefixIcon: Icon(Icons.search),
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
              ),
            ),
            Expanded(
              child: filteredMealData.isEmpty
                  ? Center(child: GFLoader(type: GFLoaderType.square,))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Hall ID')),
                          DataColumn(label: Text('Room No')),
                          DataColumn(label: Text('Student ID')),
                          DataColumn(label: Text('Total Meal')),
                          DataColumn(label: Text('Total Amount')),
                          DataColumn(label: Text('Payment')),
                          DataColumn(label: Text('Due')),
                          DataColumn(label: Text('With Feast')),
                        ],
                        rows: filteredMealData.map((meal) {
                          return DataRow(cells: [
                            DataCell(Text(meal['name'])),
                            DataCell(Text(meal['hallid'])),
                            DataCell(Text(meal['roomno'])),
                            DataCell(Text(meal['studentid'])),
                            DataCell(Text(meal['totalmeal'])),
                            DataCell(Text(meal['totalamount'])),
                            DataCell(Text(meal['payment'])),
                            DataCell(Text(meal['due'])),
                            DataCell(Text(meal['withfeast'])),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}



