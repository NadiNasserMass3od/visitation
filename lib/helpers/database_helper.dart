import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../models/visitor.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'visitors.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE visitors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            birthDate TEXT NOT NULL,
            grade INTEGER NOT NULL CHECK (grade >= 1 AND grade <= 3),
            category TEXT NOT NULL,
            fatherName TEXT NOT NULL,
            responsiblePriest TEXT NOT NULL,
            region TEXT NOT NULL,
            lastVisit TEXT,
            visitorType TEXT NOT NULL -- إضافة الحقل الجديد
          )
        ''');
      },
    );
  }

  Future<void> insertVisitor(Visitor visitor) async {
    final db = await database;
    await db.insert(
      'visitors',
      visitor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Visitor>> getVisitors() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('visitors');
    return List.generate(maps.length, (i) {
      return Visitor.fromMap(maps[i]);
    });
  }

  Future<void> updateVisitor(Visitor visitor) async {
    final db = await database;
    await db.update(
      'visitors',
      visitor.toMap(),
      where: 'id = ?',
      whereArgs: [visitor.id],
    );
  }

  Future<void> deleteVisitor(int id) async {
    final db = await database;
    await db.delete(
      'visitors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markVisited(int id) async {
    final db = await database;
    await db.update(
      'visitors',
      {'lastVisit': DateFormat('yyyy-MM-dd').format(DateTime.now())},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Visitor>> getInactiveVisitors() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('visitors');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int selectedMonths = prefs.getInt('notification_months') ?? 1;
    int selectedDays = prefs.getInt('notification_days') ?? 15;

    int totalInactiveDays = (selectedMonths * 30) + selectedDays;

    DateTime now = DateTime.now();
    return List.generate(maps.length, (i) {
      final visitor = Visitor.fromMap(maps[i]);
      DateTime lastVisit = visitor.lastVisit ?? DateTime.now();
      if (now.difference(lastVisit).inDays > totalInactiveDays - 1) {
        return visitor;
      } else {
        return null;
      }
    }).where((visitor) => visitor != null).cast<Visitor>().toList();
  }

  Future<bool> checkVisitorExists(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visitors',
      where: 'name = ?',
      whereArgs: [name],
    );

    return maps.isNotEmpty;
  }

  Future<void> deleteAllVisitors() async {
    final db = await database;
    await db.delete('visitors');
  }

  Future<void> exportVisitorsToXLSX(String outputFilePath) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('visitors');

    List<Visitor> visitors = maps.map((map) => Visitor.fromMap(map)).toList();

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // إضافة الصفوف الأولى التي تحتوي على رؤوس الأعمدة
    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('Name'),
      TextCellValue('Birth Date'),
      TextCellValue('Grade'),
      TextCellValue('Category'),
      TextCellValue('Father Name'),
      TextCellValue('Responsible Priest'),
      TextCellValue('Region'),
      TextCellValue('Last Visit'),
      TextCellValue('Visitor Type'),
    ]);

    // إضافة بيانات الزوار
    for (var visitor in visitors) {
      sheetObject.appendRow([
        TextCellValue(visitor.id?.toString() ?? ''),
        TextCellValue(visitor.name),
        TextCellValue(DateFormat('yyyy-MM-dd').format(visitor.birthDate)),
        TextCellValue(visitor.grade.toString()),
        TextCellValue(visitor.category),
        TextCellValue(visitor.fatherName),
        TextCellValue(visitor.responsiblePriest),
        TextCellValue(visitor.region),
        TextCellValue(DateFormat('yyyy-MM-dd').format(visitor.lastVisit!)),
        TextCellValue(visitor.visitorType),
      ]);
    }

    var outputFile = File(outputFilePath);
    await outputFile.create(recursive: true);
    await outputFile.writeAsBytes(excel.encode()!);
  }

  Future<void> importVisitorsFromXLSX(String inputFilePath) async {
    final db = await database;
    File file = File(inputFilePath);
    final prefs = await SharedPreferences.getInstance();
    String role = prefs.getString('role') ?? 'other';

    if (!await file.exists()) {
      throw Exception('ملف XLSX غير موجود.');
    }

    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows) {
        if (row[0]?.value == null) continue; // تخطي الصفوف الفارغة
        if (row[0]?.value.toString() == 'ID') continue; // تخطي رؤوس الأعمدة

        int id = int.tryParse(row[0]!.value.toString()) ?? 0;
        String name = row[1]?.value.toString() ?? '';
        DateTime birthDate =
            DateFormat('yyyy-MM-dd').parse(row[2]?.value.toString() ?? '');
        int grade = int.tryParse(row[3]?.value.toString() ?? '0') ?? 0;
        String category = row[4]?.value.toString() ?? '';
        String fatherName = row[5]?.value.toString() ?? '';
        String responsiblePriest = row[6]?.value.toString() ?? '';
        String region = row[7]?.value.toString() ?? '';
        DateTime? lastVisit;
        if (row.length > 8 && row[8]?.value != null) {
          lastVisit = DateFormat('yyyy-MM-dd').parse(row[8]!.value.toString());
        }
        String visitorType = row[9]?.value.toString() ?? '';

        // Apply role-based filtering
        if ((role == 'boy' && visitorType != 'boy') ||
            (role == 'girl' && visitorType != 'girl')) {
          continue; // Skip if visitor type doesn't match the role
        }

        try {
          await db.insert('visitors', {
            'id': id,
            'name': name,
            'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
            'grade': grade,
            'category': category,
            'fatherName': fatherName,
            'responsiblePriest': responsiblePriest,
            'region': region,
            'lastVisit': lastVisit != null
                ? DateFormat('yyyy-MM-dd').format(lastVisit)
                : null,
            'visitorType': visitorType,
          });
        } on DatabaseException catch (e) {
          if (await checkVisitorExists(name)) {
            throw Exception(
                'فشل استيراد الزوار: المخدوم $name موجود بالفعل في قاعدة البيانات.');
          } else {
            throw Exception('فشل استيراد الزوار: $e');
          }
        }
      }
    }
  }

  final Map<String, dynamic> accountCredentials = {
    "type": "service_account",
    "project_id": "confessionapp-437117",
    "private_key_id": "b91e3c17e2335606c74d204cb5040b6fb9120404",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCYv1DzGgkYwpEc\nKq4T5VVL6vvERSmZDEVYngYVjvIExP8igJE5/vK7D6xoE16rtLrvYatBkwud2fG/\nIZXtxT7RLdWwY/0HWprwoldYniMzpCt5Dfk21yPpnj11ZrbMBCqIHpVT8bTpopv1\niasg8m5euWXumd0a1tXDU9LYVR2C+6u6E6GhhTAqvhb3wSJIm7uC3gHHkudWLExs\nkOwbBLI8YbhVHYel4NfjyxH6O3oZoXpZMD6Bl7KebLsWxTcA8/2zxFzXviZK6tvR\nF1Pr0bZEet3Dsoo+RGfdSZvhybJsu7oLr9baQx/ltqrEY7rp8O4rxaepDguv/nOh\nKsryiFYFAgMBAAECggEACRF0mhYd26Mzb7dl8cbv7yuiakbL3yrwFAB/rnh3zEow\ntmjpFkcZPHtD+kLKIEoAvhTvkJtM+YBWnoj9KGpJHiyJLulkvHLH14jfxCJRRy/U\nJ+HpPXT8zBIJpoZkTEzkBIRCS8NCAQvXE/bqGrDh1gxOLaHjU0RVWP0JO7Aj6iJ0\n1tXNuy3geSRByNMmeJcj6ki0pppmk3PMzlQM7Eq9eyubaR7pFtP+SPvx4yVRoWTp\n4IGRXfZJzlDQaeErCa3ClqhTEaVlWdZMvKd2THrEixa/sf8MIIOEaMOoKZ2/Kb18\noOOOFhFd/oII/cyxV9XN8of70l1bIlaPUrcptfCYmQKBgQDHEmZKB5Kbqh7VqQZq\naPG3r52oN20Y3ESO7fuX2R/oSvHxysDBcjeufEdMghEZDvmyB1rw3k/8nUjky4O5\nObHjsGXJcB+j/KATsLI5J0yFBQBUfjhF+k8xN75I4t7eC4iL23gyxVRNjo6B9XNN\nwo4lo22Z1dqRMwPPIiXLwbU0zQKBgQDEbZoPLSUeYQY7ft0+BKJ/TGRtadmzT8ls\ndPhN5uK2929PRK25Rf8NaL/vT3TcEXIwe1Joh8h9uYMQMviozaMq6XeyBM+LYw7A\n5FNXqqySB0kBVb8VEYgHPN+IZ7BNGgwF+mIdVnQStvSbgOh9CsEiWz6d3WNQIo+l\nWZDBM/7mGQKBgQCjlxs3+sEf6s0sB5qeF1+L82U7t1CP/XLZgfge8O6nle79JAEC\n9zmKydZNqRUj4oqPIjw5dHeGwDoGyreUnzTwRyVeRCW8PP3PMIVFMmZPaay7wn28\nA9bQO17DxqwfDJtJUzGTh1Wf5mZ1pZ77Z8YoaATJRlQ2vhWDQiyNJMIkgQKBgBM1\niLBdQNkEsgBVerta5q0+Qj/07wY7Ej6Z/cJYhulPr0H4PGj28GdWTBbSFWKEDj+x\nf7CbPr8Uyj1mTqzrVz6WEE+Hauh9qm6wpXnYRgIN1lTcFtCvozbZ/B4xzarslipr\nfvbRgo5l9+vRImtABv0eITR89v5aMuP/q0lJlW7ZAoGBAIAiRABhEyMhgl9OgOOY\nCY91X3gAyRShwtd8BfzGvqPYsSJzrGMQkKgXQ3RZKc4lmMIHmUpczB1DBqNNwRn7\nO2HFSvf8yuqizQ3ipDFkYRkzcCKe+1WvrC0Lhcjh32Un6W4zVAi5kcs/ksrqQyAA\nieftKKbARtc9vB6iB0fOXmMH\n-----END PRIVATE KEY-----\n",
    "client_email":
        "confessionapp@confessionapp-437117.iam.gserviceaccount.com",
    "client_id": "106714545580337330165",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/confessionapp%40confessionapp-437117.iam.gserviceaccount.com"
  };
  String fileId = "1DYg3wtucY_fDKl5TJnEFbhESsAC7xMBb";
  String localExcelPath =
      '/storage/emulated/0/Download/VisitorsBackup/visitors_backup.xlsx';
  Future<void> exportAndUpdateGoogleDriveFile(String fileUrl) async {
    final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(accountCredentials),
        [drive.DriveApi.driveFileScope]);
    final driveApi = drive.DriveApi(client);

    var response = await http.get(Uri.parse(fileUrl));
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل الملف من Google Drive');
    }

    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/visitors_backup.xlsx';
    File tempFile = File(tempPath);
    await tempFile.writeAsBytes(response.bodyBytes);

    if (await tempFile.length() == 0) {
      throw Exception('فشل تحميل الملف: الملف فارغ.');
    }

    var excelGoogle = Excel.decodeBytes(await tempFile.readAsBytes());
    Sheet sheetGoogle = excelGoogle['Sheet1'];

    Map<String, Visitor> googleVisitors = {};
    Set<int> idsSet = {};
    int lastRowIndex = 0;

    // قراءة البيانات من الملف الموجود على Google Drive
    for (var i = 1; i < sheetGoogle.rows.length; i++) {
      var row = sheetGoogle.rows[i];
      if (row[1] != null &&
          row[1]!.value != null &&
          row[1]!.value.toString().isNotEmpty) {
        String name = row[1]!.value.toString();
        int? id = int.tryParse(row[0]?.value.toString() ?? '');

        // التحقق من أن الـ ID غير مكرر
        if (id != null) {
          if (idsSet.contains(id)) {
            // إذا كان الـ ID مكرراً، تحديث الـ ID باسم جديد
            id = idsSet.length + 1; // تعيين ID جديد
            row[0]?.value =
                TextCellValue(id.toString()); // تحديث الـ ID في الملف
          }
          idsSet.add(id);
        }

        DateTime? lastVisit =
            DateFormat('yyyy-MM-dd').parse(row[8]!.value.toString());

        // إضافة حقل visitorType
        String visitorType = row[9]?.value.toString() ?? '';

        googleVisitors[name] = Visitor(
          id: id,
          name: name,
          birthDate:
              DateTime.tryParse(row[2]?.value.toString() ?? '1970-01-01') ??
                  DateTime(1970, 1, 1),
          grade: int.tryParse(row[3]?.value.toString() ?? '0') ?? 0,
          category: row[4]?.value.toString() ?? '',
          fatherName: row[5]?.value.toString() ?? '',
          responsiblePriest: row[6]?.value.toString() ?? '',
          region: row[7]?.value.toString() ?? '',
          lastVisit: lastVisit,
          visitorType: visitorType, // إضافة visitorType هنا
        );

        lastRowIndex = i;
      }
    }

    // قراءة البيانات من الملف المحلي
    File localFile = File(localExcelPath);
    var excelLocal = Excel.decodeBytes(await localFile.readAsBytes());
    Sheet sheetLocal = excelLocal['Sheet1'];

    for (var row in sheetLocal.rows.skip(1)) {
      if (row[1] == null ||
          row[1]!.value == null ||
          row[1]!.value.toString().isEmpty) continue;

      String localName = row[1]!.value.toString();
      DateTime? localLastVisit =
          DateTime.tryParse(row[8]?.value.toString() ?? '');
      int? localId = int.tryParse(row[0]?.value.toString() ?? '');
      String localVisitorType = row[9]?.value.toString() ?? '';

      // التحقق من الـ ID المحلي
      if (localId != null) {
        if (idsSet.contains(localId)) {
          // إذا كان الـ ID مكرراً، تحديث الـ ID
          localId = idsSet.length + 1; // تعيين ID جديد
          row[0]?.value =
              TextCellValue(localId.toString()); // تحديث الـ ID في الملف
        }
        idsSet.add(localId);
      }

      if (googleVisitors.containsKey(localName)) {
        Visitor googleVisitor = googleVisitors[localName]!;
        if (localLastVisit != null &&
            localLastVisit.isAfter(googleVisitor.lastVisit!)) {
          sheetGoogle.rows[lastRowIndex][8]?.value = TextCellValue(
              DateFormat('yyyy-MM-dd').format(localLastVisit).toString());
          // تحديث الـ visitorType في حالة اختلافه
          if (localVisitorType != googleVisitor.visitorType) {
            sheetGoogle.rows[lastRowIndex][9]?.value =
                TextCellValue(localVisitorType);
          }
        }
      } else {
        lastRowIndex++;

        googleVisitors[localName] = Visitor(
          id: localId,
          name: localName,
          birthDate:
              DateTime.tryParse(row[2]?.value.toString() ?? '1970-01-01') ??
                  DateTime(1970, 1, 1),
          grade: int.tryParse(row[3]?.value.toString() ?? '0') ?? 0,
          category: row[4]?.value.toString() ?? '',
          fatherName: row[5]?.value.toString() ?? '',
          responsiblePriest: row[6]?.value.toString() ?? '',
          region: row[7]?.value.toString() ?? '',
          lastVisit: localLastVisit,
          visitorType: localVisitorType, // إضافة visitorType هنا
        );

        sheetGoogle.insertRowIterables([
          row[0]?.value,
          TextCellValue(localName),
          row[2]?.value,
          row[3]?.value,
          row[4]?.value,
          row[5]?.value,
          row[6]?.value,
          row[7]?.value,
          TextCellValue(DateFormat('yyyy-MM-dd')
              .format(localLastVisit ?? DateTime.now())),
          TextCellValue(localVisitorType),
        ], lastRowIndex);
      }
    }

    var updatedExcelBytes = excelGoogle.encode();
    await tempFile.writeAsBytes(updatedExcelBytes!);

    var media = drive.Media(tempFile.openRead(), tempFile.lengthSync());
    await driveApi.files.update(
      drive.File(),
      fileId,
      uploadMedia: media,
    );
  }

  Future<void> syncVisitorsData(String fileUrl) async {
    final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(accountCredentials),
        [drive.DriveApi.driveFileScope]);
    final driveApi = drive.DriveApi(client);

    // تحميل ملف Google Drive
    var response = await http.get(Uri.parse(fileUrl));
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل الملف من Google Drive');
    }

    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/visitors_backup.xlsx';
    File tempFile = File(tempPath);
    await tempFile.writeAsBytes(response.bodyBytes);

    if (await tempFile.length() == 0) {
      throw Exception('فشل تحميل الملف: الملف فارغ.');
    }

    // قراءة ملف Google Drive
    var excelGoogle = Excel.decodeBytes(await tempFile.readAsBytes());
    Sheet sheetGoogle = excelGoogle['Sheet1'];

    // قراءة ملف Excel المحلي
    File localFile = File(localExcelPath);
    var excelLocal = Excel.decodeBytes(await localFile.readAsBytes());
    Sheet sheetLocal = excelLocal['Sheet1'];

    Map<String, Visitor> googleVisitors = {};
    Set<int> idsSet = {}; // لتتبع الـ IDs المستخدمة
    int lastRowIndex = 0;

    // قراءة الزوار من ملف Google Drive
    for (var i = 1; i < sheetGoogle.rows.length; i++) {
      var row = sheetGoogle.rows[i];
      if (row[1] != null &&
          row[1]!.value != null &&
          row[1]!.value.toString().isNotEmpty) {
        String name = row[1]!.value.toString();
        int? id = int.tryParse(row[0]?.value.toString() ?? '');

        if (id != null) {
          if (idsSet.contains(id)) {
            id = idsSet.length + 1;
            row[0]?.value = TextCellValue(id.toString());
          }
          idsSet.add(id);
        }

        DateTime? lastVisit = DateTime.tryParse(row[8]?.value.toString() ?? '');
        String visitorType = row[9]?.value.toString() ?? 'boy';

        googleVisitors[name] = Visitor(
          id: id,
          name: name,
          birthDate:
              DateTime.tryParse(row[2]?.value.toString() ?? '1970-01-01') ??
                  DateTime(1970, 1, 1),
          grade: int.tryParse(row[3]?.value.toString() ?? '0') ?? 0,
          category: row[4]?.value.toString() ?? '',
          fatherName: row[5]?.value.toString() ?? '',
          responsiblePriest: row[6]?.value.toString() ?? '',
          region: row[7]?.value.toString() ?? '',
          lastVisit: lastVisit,
          visitorType: visitorType,
        );

        lastRowIndex = i;
      }
    }

    // تحديث البيانات في ملف Google Drive بناءً على البيانات في الملف المحلي
    for (var row in sheetLocal.rows.skip(1)) {
      if (row[1] == null ||
          row[1]!.value == null ||
          row[1]!.value.toString().isEmpty) continue;

      String localName = row[1]!.value.toString();
      DateTime? localBirthDate =
          DateTime.tryParse(row[2]?.value.toString() ?? '');
      int? localGrade = int.tryParse(row[3]?.value.toString() ?? '0');
      String localCategory = row[4]?.value.toString() ?? '';
      String localFatherName = row[5]?.value.toString() ?? '';
      String localResponsiblePriest = row[6]?.value.toString() ?? '';
      String localRegion = row[7]?.value.toString() ?? '';
      DateTime? localLastVisit =
          DateTime.tryParse(row[8]?.value.toString() ?? '');
      String localVisitorType = row[9]?.value.toString() ?? 'boy';

      int? localId = int.tryParse(row[0]?.value.toString() ?? '');

      if (localId != null) {
        if (idsSet.contains(localId)) {
          localId = idsSet.length + 1;
          row[0]?.value = TextCellValue(localId.toString());
        }
        idsSet.add(localId);
      }

      // إذا كان الاسم موجودًا في ملف Google Drive، تحقق من الحاجة لتحديث البيانات
      if (googleVisitors.containsKey(localName)) {
        Visitor googleVisitor = googleVisitors[localName]!;

        if (localLastVisit != null &&
            localLastVisit.isAfter(googleVisitor.lastVisit!)) {
          sheetGoogle
                  .rows[googleVisitors.keys.toList().indexOf(localName) + 1][8]
                  ?.value =
              TextCellValue(DateFormat('yyyy-MM-dd').format(localLastVisit));
        }

        if (localBirthDate != null &&
            localBirthDate != googleVisitor.birthDate) {
          sheetGoogle
                  .rows[googleVisitors.keys.toList().indexOf(localName) + 1][2]
                  ?.value =
              TextCellValue(DateFormat('yyyy-MM-dd').format(localBirthDate));
        }
        if (localGrade != null && localGrade != googleVisitor.grade) {
          sheetGoogle
              .rows[googleVisitors.keys.toList().indexOf(localName) + 1][3]
              ?.value = TextCellValue(localGrade.toString());
        }
        if (localCategory != googleVisitor.category) {
          sheetGoogle
              .rows[googleVisitors.keys.toList().indexOf(localName) + 1][4]
              ?.value = TextCellValue(localCategory);
        }
        if (localFatherName != googleVisitor.fatherName) {
          sheetGoogle
              .rows[googleVisitors.keys.toList().indexOf(localName) + 1][5]
              ?.value = TextCellValue(localFatherName);
        }
        if (localResponsiblePriest != googleVisitor.responsiblePriest) {
          sheetGoogle
              .rows[googleVisitors.keys.toList().indexOf(localName) + 1][6]
              ?.value = TextCellValue(localResponsiblePriest);
        }
        if (localRegion != googleVisitor.region) {
          sheetGoogle
              .rows[googleVisitors.keys.toList().indexOf(localName) + 1][7]
              ?.value = TextCellValue(localRegion);
        }
        if (localVisitorType !=
            googleVisitor.visitorType.toString().split('.').last) {
          sheetGoogle
              .rows[googleVisitors.keys.toList().indexOf(localName) + 1][9]
              ?.value = TextCellValue(localVisitorType); // تحديث نوع الزائر
        }
      } else {
        lastRowIndex++;

        googleVisitors[localName] = Visitor(
          id: localId,
          name: localName,
          birthDate:
              DateTime.tryParse(row[2]?.value.toString() ?? '1970-01-01') ??
                  DateTime(1970, 1, 1),
          grade: int.tryParse(row[3]?.value.toString() ?? '0') ?? 0,
          category: row[4]?.value.toString() ?? '',
          fatherName: row[5]?.value.toString() ?? '',
          responsiblePriest: row[6]?.value.toString() ?? '',
          region: row[7]?.value.toString() ?? '',
          lastVisit: localLastVisit,
          visitorType: localVisitorType,
        );

        sheetGoogle.insertRowIterables([
          row[0]?.value,
          TextCellValue(localName),
          row[2]?.value,
          row[3]?.value,
          row[4]?.value,
          row[5]?.value,
          row[6]?.value,
          row[7]?.value,
          TextCellValue(DateFormat('yyyy-MM-dd')
              .format(localLastVisit ?? DateTime.now())),
          TextCellValue(localVisitorType), // إضافة نوع الزائر الجديد
        ], lastRowIndex);
      }
    }

    // حفظ ملف Google Drive المحدث
    var updatedExcelBytes = excelGoogle.encode();
    await tempFile.writeAsBytes(updatedExcelBytes!);

    // رفع الملف المحدث إلى Google Drive
    var media = drive.Media(tempFile.openRead(), tempFile.lengthSync());
    await driveApi.files.update(
      drive.File(),
      fileId,
      uploadMedia: media,
    );
  }

  Future<void> importVisitorsFromGoogleDrive(String fileUrl) async {
    var response = await http.get(Uri.parse(fileUrl));
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل الملف من Google Drive');
    }
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/visitors_backup.xlsx';
    File tempFile = File(tempPath);
    await tempFile.writeAsBytes(response.bodyBytes);
    if (await tempFile.length() == 0) {
      throw Exception('فشل تحميل الملف: الملف فارغ.');
    }
    deleteAllVisitors();
    await importVisitorsFromXLSX(tempPath);
  }
}
