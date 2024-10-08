import 'dart:io';
import 'package:visitation/Colors/color.dart';
import 'package:visitation/models/variable.dart';
import 'package:visitation/screens/birth_day_screen.dart';
import 'package:visitation/screens/edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_visitor_screen.dart';
import 'visitor_list_screen.dart';
import 'inactive_visitors_screen.dart';
import '../helpers/notification_helper.dart';
import '../helpers/database_helper.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    NotificationHelper.initNotifications();
    NotificationHelper().scheduleDailyNotifications();

    _loadAccess();
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

  Future<void> _updateGoogleDriveFile() async {
    exportToXLSX();
    setState(() {
      isLoading = true;
    });

    try {
      await _databaseHelper.exportAndUpdateGoogleDriveFile(fileUrl);
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

  Future<void> importFromDrive() async {
    try {
      await _databaseHelper.importVisitorsFromGoogleDrive(fileUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: blue,
          content: Text(
            'تم استيراد الزوار بنجاح.',
            style: TextStyle(
              color: white,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: red,
          content: Text(
            '$e',
            style: TextStyle(
              color: white,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    exportToXLSX();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'تحذير',
              style: TextStyle(
                color: red,
              ),
            ),
            content: const Text(
                'تأكد أنك قمت بعمل نسخة احتياطية للبيانات قبل الخروج. هل تريد الخروج؟'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'لا',
                  style: TextStyle(
                    color: white,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'نعم',
                  style: TextStyle(
                    color: white,
                  ),
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Expanded(
                  flex: 8,
                  child: SizedBox(),
                ),
                const Expanded(
                  flex: 16,
                  child: Image(
                    image: AssetImage("lib/assets/images/Thanwy.png"),
                  ),
                ),
                isAdmin
                    ? Expanded(
                        flex: 4,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddVisitorScreen()),
                            ).then((added) {
                              if (added == true) {
                                setState(() {});
                              }
                            });
                          },
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
                                Icon(
                                  Icons.person_add,
                                  color: white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'إضافة مخدوم',
                                  style: TextStyle(
                                    color: white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
                const Expanded(
                  flex: 1,
                  child: SizedBox(),
                ),
                isAdmin
                    ? Expanded(
                        flex: 4,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const EditScreen()),
                            ).then((added) {
                              if (added == true) {
                                setState(() {});
                              }
                            });
                          },
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
                                Icon(
                                  Icons.edit,
                                  color: white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'تعديل وحذف مخدوم',
                                  style: TextStyle(
                                    color: white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
                const Expanded(
                  flex: 1,
                  child: SizedBox(),
                ),
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const VisitorListScreen()),
                      ).then((added) {
                        if (added == true) {
                          setState(() {});
                        }
                      });
                    },
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
                          Icon(
                            Icons.list,
                            color: white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'قائمة المخدومين',
                            style: TextStyle(
                              color: white,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
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
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const InactiveVisitorsScreen()),
                      ).then((added) {
                        if (added == true) {
                          setState(() {});
                        }
                      });
                    },
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
                          Icon(
                            Icons.warning,
                            color: white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'قائمة الافتقاد',
                            style: TextStyle(
                              color: white,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
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
                isAdmin
                    ? Expanded(
                        flex: 4,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const BirthdayListScreen()),
                            ).then((added) {
                              if (added == true) {
                                setState(() {});
                              }
                            });
                          },
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
                                Icon(
                                  Icons.card_giftcard,
                                  color: white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'أعياد الميلاد',
                                  style: TextStyle(
                                    color: white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
                const Expanded(
                  flex: 1,
                  child: SizedBox(),
                ),
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: _updateGoogleDriveFile,
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
                          Icon(
                            Icons.cloud_upload,
                            color: white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'عمل نسخة احتياطية',
                            style: TextStyle(
                              color: white,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
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
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'تحذير',
                            style: TextStyle(
                              color: red,
                            ),
                          ),
                          content: const Text(
                            'هل أنت متأكد لاسترجاع النسخة الاحتياطية للبيانات؟\nسوف يتم حذف كل البيانات المحلية!!!',
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'لا',
                                style: TextStyle(
                                  color: white,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                importFromDrive();
                                Navigator.of(context).pop(false);
                              },
                              child: Text(
                                'نعم',
                                style: TextStyle(
                                  color: white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                          Icon(
                            Icons.cloud_download,
                            color: white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'استرجاع النسخة الاحتياطية',
                            style: TextStyle(
                              color: white,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
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
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
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
                          Icon(
                            Icons.settings,
                            color: white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'الضبط',
                            style: TextStyle(
                              color: white,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
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
          ],
        ),
      ),
    );
  }
}
