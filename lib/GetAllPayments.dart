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
  List<dynamic> _students = []; // Add this line
  bool _isLoading = true;
  String _message = '';
  String _searchQuery = '';
  String? amount, date, note;
  String? selectedStudentId;
  String? _paymentIdToEdit; // Store ID of the payment being edited

  @override
  void initState() {
    super.initState();
    _fetchPayments();
    _fetchStudents();
  }

  Future<void> _fetchPayments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

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
          _students = json.decode(response.body); // Initialize _students here
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

  Future<void> _addOrUpdatePayment({String? paymentId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (selectedStudentId == null) {
      setState(() {
        _message = 'Please select a student';
        return;
      });
    }

    final paymentData = {
      'stdid': selectedStudentId,
      'amount': amount,
      'date': date,
      'note': note ?? '',
    };

    try {
      final response = await http.post(
        Uri.parse(paymentId != null
            ? '${Config.baseUrl}?updatepayment' // Endpoint for updating payment
            : '${Config.baseUrl}?insertpayment'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(paymentId != null
            ? {'id': paymentId, ...paymentData} // Include ID for update
            : paymentData),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Payment processed successfully';
          _fetchPayments(); // Refresh the payments list
          _paymentIdToEdit = null; // Reset edit ID
        });
      } else {
        setState(() {
          _message = 'Failed to process payment';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
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
        final searchLower = _searchQuery.toLowerCase();

        return nameLower.contains(searchLower) ||
            roomNoLower.contains(searchLower) ||
            hallNoLower.contains(searchLower);
      }).toList();
    });
  }

  void _showEditPaymentDialog(Map<String, dynamic> payment) {
    final amountController = TextEditingController(text: payment['amount'].toString());
    final dateController = TextEditingController(text: payment['date']);
    final noteController = TextEditingController(text: payment['note']);

    setState(() {
      _paymentIdToEdit = payment['id']; // Store ID for edit
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: payment['name']),
              readOnly: true,
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Room No',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: payment['roomno'].toString()),
              readOnly: true,
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: amountController,
              onChanged: (value) {
                setState(() {
                  amount = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              controller: dateController,
              onChanged: (value) {
                setState(() {
                  date = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              controller: noteController,
              onChanged: (value) {
                setState(() {
                  note = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _paymentIdToEdit = null; // Reset edit ID on cancel
              });
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addOrUpdatePayment(paymentId: _paymentIdToEdit);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    final amountController = TextEditingController();
    final dateController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStudentId,
              decoration: InputDecoration(
                labelText: 'Select Student',
                border: OutlineInputBorder(),
              ),
              items: _students.map((student) {
                return DropdownMenuItem<String>(
                  value: student['id'],
                  child: Text(student['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStudentId = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: amountController,
              onChanged: (value) {
                setState(() {
                  amount = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              controller: dateController,
              onChanged: (value) {
                setState(() {
                  date = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              controller: noteController,
              onChanged: (value) {
                setState(() {
                  note = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addOrUpdatePayment();
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payments', style: TextStyle(color: Colors.black),),
        backgroundColor:const Color.fromARGB(255, 148, 227, 249),
        shadowColor: Colors.lightBlueAccent[100],
        elevation: 4,
      ),
      body: Container(
        color: const Color.fromARGB(255, 208, 239, 255),
        child: _isLoading
            ? Center(child: GFLoader(type: GFLoaderType.circle,))
            : Column(
                children: [
                  SizedBox(height: 10,),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Search Payments',
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
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: _filterPayments,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 148, 227, 249), // Updated parameter
                        padding: EdgeInsets.all(16),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _showAddPaymentDialog,
                      child: Text('Add Payment', style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Room No')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _filteredPayments.map((payment) {
                          return DataRow(
                            cells: [
                              DataCell(Text(payment['id'].toString())),
                              DataCell(Text(payment['name'])),
                              DataCell(Text(payment['roomno'].toString())),
                              DataCell(Text(payment['amount'].toString())),
                              DataCell(Text(payment['date'])),
                              DataCell(Text(payment['note'] ?? '')),
                              DataCell(
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _showEditPaymentDialog(payment),
                                ),
                              ),
                            ],
                          );
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
