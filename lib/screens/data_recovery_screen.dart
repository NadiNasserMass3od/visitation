import 'dart:io';
import 'package:visitation/Colors/color.dart';
import 'package:visitation/helpers/database_helper.dart';
import 'package:visitation/models/variable.dart';
import 'package:visitation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataRecoveryScreen extends StatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  State<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends State<DataRecoveryScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _hasRecoveredData = false;

  @override
  void initState() {
    super.initState();
    _checkRecoveryStatus();
  }

  Future<void> _checkRecoveryStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasRecoveredData = prefs.getBool('hasRecoveredData') ?? false;
    });
  }

  Future<void> exportToXLSX() async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      final backupDirectory = Directory('${directory.path}/VisitorsBackup');
      if (!await backupDirectory.exists()) {
        await backupDirectory.create();
      }

      String outputFile = '${backupDirectory.path}/visitors_backup.xlsx';
      await _databaseHelper.exportVisitorsToXLSX(outputFile);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: blue,
          content: Text(
            'تم تصدير البيانات كملف XLSX بنجاح',
            style: TextStyle(color: white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: red,
          content: Text(
            'حدث خطأ أثناء تصدير البيانات',
            style: TextStyle(color: white),
          ),
        ),
      );
    }
  }


  Future<void> importFromDrive() async {
    try {
      await _databaseHelper.importVisitorsFromGoogleDrive(fileUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: blue,
          content: Text(
            'تم التحميل بنجاح.',
            style: TextStyle(color: white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setBool('hasRecoveredData', true);
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: red,
          content: Text(
            '$e',
            style: TextStyle(color: white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    exportToXLSX();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              flex: 14,
              child: SizedBox(),
            ),
            Expanded(
              flex: 4,
              child: Text(
                "خدمة شباب ثانوي",
                style: TextStyle(
                  color: blue,
                  fontSize: MediaQuery.of(context).size.width * 0.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Expanded(
              flex: 16,
              child: Image(
                image: AssetImage("lib/assets/images/Thanwy.png"),
              ),
            ),
            const Expanded(
              flex: 2,
              child: SizedBox(),
            ),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: importFromDrive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تحميل البيانات',
                        style: TextStyle(
                          color: white,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
            Expanded(
              flex: 2,
              child: Text(
                !_hasRecoveredData
                    ? "يجب أن تسترجع البيانات مرة واحدة على الأقل"
                    : "",
                style: TextStyle(
                  color: red,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
            ),
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: _hasRecoveredData
                    ? () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'العمل بالبيانات الموجودة',
                        style: TextStyle(
                          color: _hasRecoveredData
                              ? white
                              : black.withOpacity(0.4),
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Expanded(
              flex: 10,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
