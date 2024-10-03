import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visitation/Colors/color.dart';
import '../helpers/database_helper.dart';
import '../models/visitor.dart';

class VisitorListScreen extends StatefulWidget {
  const VisitorListScreen({super.key});

  @override
  VisitorListScreenState createState() => VisitorListScreenState();
}

class VisitorListScreenState extends State<VisitorListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Visitor> _visitors = [];
  List<Visitor> _filteredVisitors = [];
  String _searchQuery = '';

  String? selectedGrade;
  String? selectedCategory;
  String? selectedFatherName;
  String? selectedResponsiblePriest;
  String? selectedRegion;
  String? selectedVisitorType;
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
    _loadVisitors();
    _loadAccess();
  }

  Future<void> _loadVisitors() async {
    List<Visitor> list = await _databaseHelper.getVisitors();
    list.sort((a, b) => a.name.compareTo(b.name));
    setState(() {
      _visitors = list;
      _filteredVisitors = list;
    });
  }

  void _filterVisitors() {
    setState(() {
      _filteredVisitors = _visitors.where((visitor) {
        bool matchesName =
            visitor.name.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesFatherName = selectedFatherName == null ||
            visitor.fatherName == selectedFatherName;

        bool matchesResponsiblePriest = selectedResponsiblePriest == null ||
            visitor.responsiblePriest == selectedResponsiblePriest;

        bool matchesRegion =
            selectedRegion == null || visitor.region == selectedRegion;

        bool matchesGrade =
            selectedGrade == null || visitor.grade.toString() == selectedGrade;

        bool matchesCategory =
            selectedCategory == null || visitor.category == selectedCategory;

        // فلترة حسب النوع (ولد/بنت)
        bool matchesVisitorType = selectedVisitorType == null ||
            (selectedVisitorType == 'boy' && visitor.visitorType == 'boy') ||
            (selectedVisitorType == 'girl' && visitor.visitorType == 'girl');

        return matchesName &&
            matchesFatherName &&
            matchesResponsiblePriest &&
            matchesRegion &&
            matchesGrade &&
            matchesCategory &&
            matchesVisitorType;
      }).toList();
    });
  }

  String _calculateInactiveDuration(DateTime lastVisitDate) {
    final now = DateTime.now();
    final difference = now.difference(lastVisitDate);

    final months = difference.inDays ~/ 30;
    final days = difference.inDays % 30;

    if (months == 0 && days == 0) {
      return 'اليوم';
    } else if (days == 0) {
      return months == 1 ? '$months شهر' : '$months شهور';
    } else if (months == 0) {
      return days == 1 ? '$days يوم' : '$days أيام';
    } else {
      return months == 1 && days == 1
          ? '$months شهر و $days يوم'
          : months == 1
              ? '$months شهر و $days أيام'
              : '$months شهور و $days يوم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.08,
          ),
          Text(
            'قائمة المخدومين',
            style: TextStyle(
              color: blue,
              fontSize: MediaQuery.of(context).size.height * 0.035,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: blue.withOpacity(0.4),
                      selectionHandleColor: blue,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterVisitors();
                      });
                    },
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
                      hintText: 'بحث...',
                      suffixIcon: Icon(
                        Icons.search,
                        color: blue,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: DropdownButton2<String>(
                        hint: const Text(
                          'أب الاعتراف',
                          overflow: TextOverflow.ellipsis,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                        isExpanded: true,
                        value: selectedFatherName,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedFatherName = newValue;
                            _filterVisitors();
                          });
                        },
                        items: _visitors
                            .map((visitor) => visitor.fatherName)
                            .toSet()
                            .toList()
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    isAdmin
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: DropdownButton2<String>(
                              value: selectedVisitorType,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedVisitorType = newValue;
                                  _filterVisitors();
                                });
                              },
                              items: const [
                                DropdownMenuItem<String>(
                                  value: 'boy',
                                  child: Text(
                                    'ولد',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'girl',
                                  child: Text(
                                    'بنت',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              isExpanded: true,
                              dropdownStyleData: DropdownStyleData(
                                width: MediaQuery.of(context).size.width * 0.5,
                              ),
                              iconStyleData:
                                  IconStyleData(iconEnabledColor: blue),
                              hint: const Text(
                                'اختر النوع',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : const SizedBox(),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: DropdownButton2<String>(
                        hint: const Text(
                          'الخادم المسؤول',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                        isExpanded: true,
                        value: selectedResponsiblePriest,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedResponsiblePriest = newValue;
                            _filterVisitors();
                          });
                        },
                        items: _visitors
                            .map((visitor) => visitor.responsiblePriest)
                            .toSet()
                            .toList()
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: const Text(
                          'السنة الدراسية',
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: selectedGrade,
                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGrade = newValue;
                            _filterVisitors();
                          });
                        },
                        items: _visitors
                            .map((visitor) => visitor.grade)
                            .toSet()
                            .toList()
                            .map<DropdownMenuItem<String>>((int value) {
                          return DropdownMenuItem<String>(
                            value: value.toString(),
                            child: Text(
                              value.toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                        hint: const Text(
                          'اختر الفئة',
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: selectedCategory,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue;
                            _filterVisitors();
                          });
                        },
                        items: _visitors
                            .map((visitor) => visitor.category)
                            .toSet()
                            .toList()
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: DropdownButton2<String>(
                        hint: const Text(
                          'اختر المنطقة',
                          overflow: TextOverflow.ellipsis,
                        ),
                        isExpanded: true,
                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                        value: selectedRegion,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRegion = newValue;
                            _filterVisitors();
                          });
                        },
                        items: _visitors
                            .map((visitor) => visitor.region)
                            .toSet()
                            .toList()
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            selectedFatherName = null;
                            selectedResponsiblePriest = null;
                            selectedGrade = null;
                            selectedCategory = null;
                            selectedRegion = null;
                            selectedVisitorType = null;
                            _filterVisitors();
                          });
                        },
                        icon: Icon(
                          Icons.cancel_outlined,
                          color: red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredVisitors.isEmpty
                ? const Center(child: Text('لا يوجد مخدومين'))
                : ListView.builder(
                    itemCount: _filteredVisitors.length,
                    itemBuilder: (context, index) {
                      Visitor visitor = _filteredVisitors[index];
                      final lastVisitDate = visitor.lastVisit ??
                          DateTime.now(); // استخدام قيمة افتراضية إذا كانت null
                      final inactiveDuration =
                          _calculateInactiveDuration(lastVisitDate);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(
                              '${visitor.name} (سنة ${visitor.grade} ثانوي ${visitor.category})'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'تاريخ الميلاد: ${DateFormat('dd-MM-yyyy').format(visitor.birthDate)}'),
                              Text(
                                  '${visitor.fatherName} -  ${visitor.responsiblePriest}'),
                              Text('المنطقة: ${visitor.region}'),
                              Text('الفترة: $inactiveDuration'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'العدد: ${_filteredVisitors.length}',
              style: TextStyle(
                fontSize: 16,
                color: blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
