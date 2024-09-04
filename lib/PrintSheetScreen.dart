import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import the PDF viewer package
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mealapp/config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectDateScreen extends StatefulWidget {
  @override
  _SelectDateScreenState createState() => _SelectDateScreenState();
}

class _SelectDateScreenState extends State<SelectDateScreen> {
  final _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _message = '';
  Uint8List? _pdfBytes; // Store the PDF bytes for displaying

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = _selectedDate;
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != initialDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _generateAndDisplayPdf(String date) async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

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
        Uri.parse('${Config.baseUrl}?printmealstatustoday=$date'),
        headers: {
          'Authorization': '$token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> listData = json.decode(response.body);
        
        final Map<String, List<Map<String, String>>> groupedData = {};
        for (var item in listData) {
          if (item is Map<String, dynamic>) {
            String roomNo = item['roomno'].toString();
            if (!groupedData.containsKey(roomNo)) {
              groupedData[roomNo] = [];
            }
            groupedData[roomNo]!.add({
              'name': item['name'].toString(),
              'lunch': '',
              'dinner': '',
            });
          }
        }

        final pdf = pw.Document();

        pdf.addPage(
          pw.MultiPage(
            build: (pw.Context context) {
              return [
                pw.Text(
                  'Meal Status for $date',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                ...groupedData.entries.map((entry) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Room No: ${entry.key}',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Table.fromTextArray(
                        headers: ['Name', 'Lunch', 'Dinner'],
                        data: entry.value.map((item) {
                          return [
                            item['name'],
                            item['lunch'],
                            item['dinner'],
                          ];
                        }).toList(),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ];
            },
          ),
        );

        _pdfBytes = await pdf.save();
        setState(() {
          // Clear the path if using bytes
        });

        // Request storage permission
        await _requestStoragePermission();

        // Open a directory picker
        final result = await FilePicker.platform.getDirectoryPath();

        if (result != null) {
          try {
            // Path to save the PDF
            final newFilePath = '${result}/meal_status_${DateFormat('yyyyMMdd').format(_selectedDate)}.pdf';
            
            // Save the PDF to the selected directory
            final file = File(newFilePath);
            await file.writeAsBytes(_pdfBytes!);
            
            setState(() {
              _message = 'PDF downloaded successfully to: $newFilePath';
            });
          } catch (e) {
            setState(() {
              _message = 'Error while downloading PDF: $e';
            });
          }
        } else {
          setState(() {
            _message = 'No directory selected.';
          });
        }
      } else {
        setState(() {
          _message = 'Failed to fetch data';
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

  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate and Download PDF'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Date',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final date = _dateController.text;
                      if (date.isNotEmpty) {
                        _generateAndDisplayPdf(date);
                      } else {
                        setState(() {
                          _message = 'Please select a date';
                        });
                      }
                    },
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Generate PDF'),
              style: ElevatedButton.styleFrom(
                shadowColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            _pdfBytes != null
                ? Expanded(
                    child: PDFView(
                      pdfData: _pdfBytes,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: false,
                      pageFling: true,
                      pageSnap: true,
                    ),
                  )
                : Container(),
            SizedBox(height: 20),
            _pdfBytes != null
                ? ElevatedButton(
                    onPressed: () async {
                      final directory = await getApplicationDocumentsDirectory();
                      final filePath = '${directory.path}/meal_status_${DateFormat('yyyyMMdd').format(_selectedDate)}.pdf';
                      final file = File(filePath);
                      await file.writeAsBytes(_pdfBytes!);
                      setState(() {
                        _message = 'PDF saved to ${filePath}';
                      });
                    },
                    child: Text('Save PDF'),
                  )
                : Container(),
            SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SelectDateScreen(),
    routes: {
      '/print-sheets': (context) => SelectDateScreen(),
    },
  ));
}
