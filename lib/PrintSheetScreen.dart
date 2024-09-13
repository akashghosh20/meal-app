import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mealapp/config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart'; // Import pdf for specifying paper size
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
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

    if (pickedDate != initialDate) {
      setState(() {
        _selectedDate = pickedDate!;
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

            // Logic for status mapping
            String lunchStatus = (item['statusnow'] == '1' && item['type'] == '1') ? 'Present' : 'Absent';
            String dinnerStatus = (item['statusnow'] == '1' && item['type'] == '2') ? 'Present' : 'Absent';

            groupedData[roomNo]!.add({
              'name': item['name'].toString(),
              'lunch': lunchStatus,
              'dinner': dinnerStatus,
            });
          }
        }

        final pdf = pw.Document();

        // Add A4 size page and dynamically design the table to fill the page
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4, // Set A4 paper size
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
                        border: pw.TableBorder.all(),
                        cellStyle: pw.TextStyle(fontSize: 12),
                        headerStyle: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        cellAlignment: pw.Alignment.center,
                        columnWidths: {
                          0: const pw.FlexColumnWidth(3),
                          1: const pw.FlexColumnWidth(1),
                          2: const pw.FlexColumnWidth(1),
                        },
                        data: entry.value.map((item) {
                          return [
                            item['name'],
                            item['lunch'] ?? '',
                            item['dinner'] ?? '',
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

        // Get the application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'meal_status_${DateFormat('yyyyMMdd').format(_selectedDate)}.pdf';
        final filePath = '${directory.path}/$fileName';

        // Save the PDF to the documents directory
        final file = File(filePath);
        await file.writeAsBytes(_pdfBytes!);

        // Share the PDF file
        await _sharePdfFile(filePath);

        setState(() {
          _message = 'PDF generated successfully and shared!';
        });
      } else {
        setState(() {
          _message = 'Failed to fetch data, status code: ${response.statusCode}';
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


  Future<void> _sharePdfFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Check out this PDF');
    } catch (e) {
      print('Error sharing file: $e');
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
        title: Text('Generate and Share PDF'),
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
                  ? GFLoader(type: GFLoaderType.square,)
                  : Text('Generate PDF'),
              style: ElevatedButton.styleFrom(
                shadowColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
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
