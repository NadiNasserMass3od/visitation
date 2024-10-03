import 'dart:io';
import 'package:visitation/Colors/color.dart';
import 'package:visitation/helpers/database_helper.dart';
import 'package:visitation/helpers/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedMonths = 1;
  int _selectedDays = 15;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool isLoading = false;
  bool isAdmin = false;

  Future<void> _loadAccess() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAdmin = prefs.getString('role') == 'other' ? true : false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationTime();
    _loadDuration();
    _loadAccess();
  }

  Future<void> _loadNotificationTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? hour = prefs.getInt('notification_hour');
    int? minute = prefs.getInt('notification_minute');

    if (hour != null && minute != null) {
      setState(() {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  Future<void> _loadDuration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMonths = prefs.getInt('notification_months') ?? 1;
      _selectedDays = prefs.getInt('notification_days') ?? 15;
    });
  }

  Future<void> _saveNotificationTime(TimeOfDay time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('notification_hour', time.hour);
    prefs.setInt('notification_minute', time.minute);
  }

  Future<void> _saveDuration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('notification_months', _selectedMonths);
    prefs.setInt('notification_days', _selectedDays);
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: blue,
            hintColor: blue,
            colorScheme: ColorScheme.light(
              primary: blue,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: white,
                backgroundColor: blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _saveNotificationTime(picked);
      NotificationHelper().scheduleDailyNotifications();
    }
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
            style: TextStyle(
              color: white,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: red,
          content: Text(
            'حدث خطأ أثناء تصدير البيانات',
            style: TextStyle(
              color: white,
            ),
          ),
        ),
      );
    }
  }

  Future<void> importFromXLSX() async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      final backupDirectory = Directory('${directory.path}/VisitorsBackup');
      String inputFile = '${backupDirectory.path}/visitors_backup.xlsx';

      if (await File(inputFile).exists()) {
        await _databaseHelper.importVisitorsFromXLSX(inputFile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: blue,
            content: Text(
              'تم استيراد البيانات بنجاح',
              style: TextStyle(
                color: white,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: red,
            content: Text(
              'لا يوجد ملف لاستيراده',
              style: TextStyle(
                color: white,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: red,
          content: Text(
            'حدث خطأ أثناء استيراد البيانات',
            style: TextStyle(
              color: white,
            ),
          ),
        ),
      );
    }
  }

  Future<void> import() async {
    _databaseHelper.deleteAllVisitors();
    importFromXLSX();
  }

  String fileId = "1DYg3wtucY_fDKl5TJnEFbhESsAC7xMBb";

  Future<void> _updateDataGoogleDriveFile() async {
    String fileUrl = 'https://drive.google.com/uc?export=download&id=$fileId';

    exportToXLSX();
    setState(() {
      isLoading = true;
    });

    try {
      await _databaseHelper.syncVisitorsData(fileUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: blue,
          content: Text(
            "تم تحديث الملف بنجاح على Google Drive!",
            style: TextStyle(
              color: white,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: red,
          content: Text(
            "حدث خطأ أثناء تحديث الملف: $e",
            style: TextStyle(
              color: white,
            ),
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.08,
            ),
            Text(
              'الضبط',
              style: TextStyle(
                color: blue,
                fontSize: MediaQuery.of(context).size.height * 0.035,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.08,
            ),
            Row(
              children: [
                Text(
                  'وقت الاشعارات',
                  style: TextStyle(
                    color: black,
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'وقت التنبية: ${_selectedTime.format(context)}',
                    style: TextStyle(
                      color: black,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _selectTime(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer,
                            color: white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'ضبط وقت الاشعارات',
                            style: TextStyle(
                              color: white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.04,
            ),
            Row(
              children: [
                Text(
                  'مدة الافتقاد',
                  style: TextStyle(
                    color: black,
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            "عدد الأيام",
                            style: TextStyle(
                              color: black,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                          DropdownButton<int>(
                            value: _selectedDays,
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedDays = newValue!;
                                _saveDuration();
                              });
                            },
                            iconEnabledColor: blue,
                            items: List.generate(31, (index) => index)
                                .map((day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day.toString()),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            "عدد الأشهر",
                            style: TextStyle(
                              color: black,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                          DropdownButton<int>(
                            value: _selectedMonths,
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedMonths = newValue!;
                                _saveDuration();
                              });
                            },
                            iconEnabledColor: blue,
                            items: List.generate(13, (index) => index)
                                .map((month) => DropdownMenuItem(
                                      value: month,
                                      child: Text(month.toString()),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  /*           Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            "عدد الأيام",
                            style: TextStyle(
                              color: black,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                          DropdownButton<int>(
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedDays = newValue!;
                                _saveDuration();
                              });
                            },
                            items: List.generate(13, (index) => index)
                                .map((month) => DropdownMenuItem(
                                      value: month,
                                      child: Text(month.toString()),
                                    ))
                                .toList(),
                            iconEnabledColor: blue,
                            isExpanded: true,
                            value: _selectedDays,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            "عدد الأشهر",
                            style: TextStyle(
                              color: black,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                          DropdownButton<int>(
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedMonths = newValue!;
                                _saveDuration();
                              });
                            },
                            items: List.generate(31, (index) => index)
                                .map((day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day.toString()),
                                    ))
                                .toList(),
                            iconEnabledColor: blue,
                            isExpanded: true,
                            value: _selectedMonths,
                          ),
                        ],
                      ),
                    ),
                  ),
              */
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.04,
            ),
            Row(
              children: [
                Text(
                  'بيانات',
                  style: TextStyle(
                    color: black,
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.2,
                0,
                MediaQuery.of(context).size.width * 0.2,
                0,
              ),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: exportToXLSX,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file_outlined,
                            color: white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'تصدير ملف Excel',
                            style: TextStyle(
                              color: white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  ElevatedButton(
                    onPressed: import,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sim_card_download_outlined,
                            color: white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'استراد ملف Excel',
                            style: TextStyle(
                              color: white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  isAdmin
                      ? ElevatedButton(
                          onPressed: _updateDataGoogleDriveFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.width * 0.12,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_to_drive,
                                  color: white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'تصدير مع تعديل البيانات',
                                  style: TextStyle(
                                    color: white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}
