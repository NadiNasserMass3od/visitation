import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visitation/Colors/color.dart';
import 'package:visitation/models/variable.dart';
import '../helpers/database_helper.dart';
import '../models/visitor.dart';

class AddVisitorScreen extends StatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  _AddVisitorScreenState createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  DateTime _birthDate = DateTime.now();
  int? _grade;
  String _category = '';
  String _fatherName = '';
  String _responsiblePriest = '';
  String _region = '';
  String _visitorType = '';
  DateTime _lastVisitDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFathersAndPriests();
    fathers.sort();
    priests.sort();
    regionlist.sort();
  }

  Future<void> _loadFathersAndPriests() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fathers = prefs.getStringList('fathers') ??
          [
            '⠀',
            'أبونا سلامة',
            'أبونا رويس',
            'أبونا رافائيل',
            'أبونا دانيال',
            'أبونا بافلي',
            'أبونا دميان',
            'أبونا أبادير',
            'أبونا صموئيل',
            'أبونا يوئيل',
            'أبونا متياس'
          ];
      priests = prefs.getStringList('priests') ??
          [
            '⠀',
            'دكتور مدحت سليمان',
            'أ. جوزيف جمال',
            'م. كرستينا فؤاد',
            'أ. جرجس نسيم',
            'أ. جوزيف حليم',
            'أ. أبانوب مراد',
            'أ. هدية رشدي',
            'أ. سلامة مرزق',
            'معلم ساويرس',
            'م. أمورة حنا',
            'م. أماني',
            'م. كرستينا نتعي',
            'م. هناء فارس',
            'م. نسمة حليم',
            'م. نيفين أنور',
            'م. رانيا جمال',
            'م. مارينا',
            'أ. مايكل',
            'أ. نادي',
            'أ. توماس يوسف',
            'أ. أبانوب حنا',
            'م. ماريانا عاطف',
            'أ. صفوت',
            'أ. سامح',
            'أ. مينا أسكندس',

          ];
      regionlist = prefs.getStringList('regionlist') ??
          [
            '⠀',
            'غرب',
            'درب الزن',
            'بحري',
            'شرق',
          ];
      fathers.sort();
      priests.sort();
      regionlist.sort();
    });
  }

  Future<void> _saveFathersAndPriests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fathers', fathers);
    await prefs.setStringList('priests', priests);
    await prefs.setStringList('regionlist', regionlist);
  }

  void _addVisitor() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      bool exists = await DatabaseHelper().checkVisitorExists(_name);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: red,
            content: Text(
              'المخدوم $_name موجود بالفعل',
              style: TextStyle(color: white),
            ),
          ),
        );
        return;
      }

      DatabaseHelper()
          .insertVisitor(
        Visitor(
          name: _name,
          birthDate: _birthDate,
          grade: _grade!,
          category: _category == '⠀' ? 'unknow' : _category,
          fatherName: _fatherName == '⠀' ? 'unknow' : _fatherName,
          responsiblePriest:
              _responsiblePriest == '⠀' ? 'unknow' : _responsiblePriest,
          region: _region == '⠀' ? 'unknow' : _region,
          lastVisit: _lastVisitDate,
          visitorType: _visitorType,
        ),
      )
          .then((_) {
        Navigator.pop(context, true);
      });
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _addNewName(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = '';
        return AlertDialog(
          title: Text(
            type == 'father'
                ? 'إضافة أب اعتراف جديد'
                : type == 'priest'
                    ? 'إضافة خادم جديد'
                    : 'إضافة منطقة جديد',
          ),
          content: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                selectionColor: blue.withOpacity(0.4),
                selectionHandleColor: blue,
              ),
            ),
            child: TextFormField(
              cursorColor: blue,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: blue,
                    width: 3,
                    style: BorderStyle.solid,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: blue,
                  ),
                ),
                labelStyle: TextStyle(color: black),
                labelText: type == 'father'
                    ? 'اسم أب الاعتراف الجديد'
                    : type == 'priest'
                        ? 'اسم الخادم الجديد'
                        : 'اسم المنطقة الجديد',
              ),
              onChanged: (value) => newName = value,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: blue),
              onPressed: () {
                if (newName.isNotEmpty) {
                  setState(() {
                    if (type == 'father') {
                      fathers.add(newName);
                      _fatherName = newName;
                      fathers.sort();
                    } else if (type == 'priest') {
                      priests.add(newName);
                      _responsiblePriest = newName;
                      priests.sort();
                    } else {
                      regionlist.add(newName);
                      regionlist.sort();
                      _region = newName;
                    }
                    _saveFathersAndPriests();
                  });
                }
                Navigator.pop(context);
              },
              child: Text(
                'إضافة',
                style: TextStyle(color: white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: 
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.08,
                ),
                Text(
                  'إضافة مخدوم',
                  style: TextStyle(
                    color: blue,
                    fontSize: MediaQuery.of(context).size.height * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.01,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.08,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        selectionColor: blue.withOpacity(0.4),
                        selectionHandleColor: blue,
                      ),
                    ),
                    child: TextFormField(
                      cursorColor: blue,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: blue,
                            width: 3,
                            style: BorderStyle.solid,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: blue,
                          ),
                        ),
                        labelStyle: TextStyle(color: black),
                        labelText: 'الاسم',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'أدخل الاسم';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value!,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.07,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "تاريخ الميلاد: ${DateFormat('dd-MM-yyyy').format(_birthDate)}",
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: blue,
                          ),
                          onPressed: () => _selectDate(context),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: blue.withOpacity(0.4),
                      selectionHandleColor: blue,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _fatherName.isNotEmpty ? _fatherName : null,
                    iconEnabledColor: blue,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                        ),
                      ),
                      labelStyle: TextStyle(color: black),
                      labelText: 'أب الاعتراف',
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.add,
                          color: blue,
                        ),
                        onPressed: () => _addNewName('father'),
                      ),
                    ),
                    items: fathers
                        .map((father) => DropdownMenuItem(
                              value: father,
                              child: Text(father),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _fatherName = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'اختار أب الاعتراف';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: blue.withOpacity(0.4),
                      selectionHandleColor: blue,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    iconEnabledColor: blue,
                    value: _responsiblePriest.isNotEmpty
                        ? _responsiblePriest
                        : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                        ),
                      ),
                      labelStyle: TextStyle(color: black),
                      labelText: 'الخادم المسؤول',
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.add,
                          color: blue,
                        ),
                        onPressed: () => _addNewName('priest'),
                      ),
                    ),
                    items: priests
                        .map((priest) => DropdownMenuItem(
                              value: priest,
                              child: Text(priest),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _responsiblePriest = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'اختار الخادم المسؤول';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: blue.withOpacity(0.4),
                      selectionHandleColor: blue,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    iconEnabledColor: blue,
                    value: _region.isNotEmpty ? _region : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                        ),
                      ),
                      labelStyle: TextStyle(color: black),
                      labelText: 'المنطقة',
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.add,
                          color: blue,
                        ),
                        onPressed: () => _addNewName('region'),
                      ),
                    ),
                    items: regionlist
                        .map((region) => DropdownMenuItem(
                              value: region,
                              child: Text(region),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _region = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'اختار المنطقة';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: blue.withOpacity(0.4),
                      selectionHandleColor: blue,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    iconEnabledColor: blue,
                    value: _grade?.toString(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                        ),
                      ),
                      labelStyle: TextStyle(color: black),
                      labelText: 'الصف الدراسي',
                    ),
                    items: gradesList
                        .map((grade) => DropdownMenuItem(
                              value: grade,
                              child: Text('الصف $grade'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _grade = int.parse(value!);
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'اختار الصف الدراسي';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: blue.withOpacity(0.4),
                      selectionHandleColor: blue,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    iconEnabledColor: blue,
                    value: _category.isNotEmpty ? _category : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                        ),
                      ),
                      labelStyle: TextStyle(color: black),
                      labelText: 'الفئة',
                    ),
                    items: categoriesList
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'اختار الفئة';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: blue.withOpacity(0.4),
                      selectionHandleColor: blue,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    iconEnabledColor: blue,
                    value: _visitorType.isNotEmpty ? _visitorType : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                        ),
                      ),
                      labelStyle: TextStyle(color: black),
                      labelText: 'النوع',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'boy',
                        child: Text('ولد'),
                      ),
                      DropdownMenuItem(
                        value: 'girl',
                        child: Text('بنت'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _visitorType = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'اختار النوع';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                ElevatedButton(
                  onPressed: _addVisitor,
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
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        ),
      ),
    );
  }
}
