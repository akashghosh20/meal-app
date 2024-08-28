import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:http/http.dart' as http;
import 'package:mealapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<dynamic> _payments = [];
  List<dynamic> _filteredPayments = [];
  bool _isLoading = true;
  String _message = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      setState(() {
        _message = 'Auth token not found';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}?getallpayment'),
        headers: {
          'Authorization': '$token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _payments = json.decode(response.body);
          _filteredPayments = _payments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _message = 'Failed to fetch payments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPayments(String query) {
    setState(() {
      _searchQuery = query;
      _filteredPayments = _payments.where((payment) {
        final nameLower = payment['name'].toLowerCase();
        final roomNoLower = payment['roomno'].toString().toLowerCase();
        final hallNoLower = payment['hallid'].toString().toLowerCase();
        final amountLower = payment['amount'].toString().toLowerCase();
        final dateLower = payment['date'].toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        return nameLower.contains(searchLower) ||
            roomNoLower.contains(searchLower) ||
            hallNoLower.contains(searchLower) ||
            amountLower.contains(searchLower) ||
            dateLower.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payments'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _filterPayments,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: GFLoader(type: GFLoaderType.circle,))
                : _filteredPayments.isEmpty
                    ? Center(child: Text(_message.isNotEmpty ? _message : 'No payments found'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Hall No')),
                            DataColumn(label: Text('Room No')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Edit')),
                          ],
                          rows: _filteredPayments.map((payment) {
                            return DataRow(cells: [
                              DataCell(Text(payment['hallid'].toString())),
                              DataCell(Text(payment['roomno'].toString())),
                              DataCell(Text(payment['name'].toString())),
                              DataCell(Text(payment['amount'].toString())),
                              DataCell(Text(payment['date'].toString())),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () {
                                    // Implement the edit functionality
                                  },
                                  child: Text('Edit'),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PaymentScreen(),
  ));
}
