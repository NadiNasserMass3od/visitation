import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visitation/Colors/color.dart';
import '../helpers/database_helper.dart';
import '../models/visitor.dart';

class BirthdayListScreen extends StatefulWidget {
  const BirthdayListScreen({super.key});

  @override
  _BirthdayListScreenState createState() => _BirthdayListScreenState();
}

class _BirthdayListScreenState extends State<BirthdayListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Visitor> _visitors = [];
  List<Visitor> _filteredVisitors = [];

  String? selectedMonth;
  String? selectedDay;
  String? selectedGrade;
  String? selectedCategory;
  String searchQuery = '';
  String? selectedVisitorType;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    List<Visitor> list = await _databaseHelper.getVisitors();
    setState(() {
      _visitors = list;
      _filteredVisitors = list;
    });
  }

  void _filterVisitors() {
    setState(() {
      _filteredVisitors = _visitors.where((visitor) {
        final birthMonth = DateFormat('MM').format(visitor.birthDate);
        final birthDay = DateFormat('dd').format(visitor.birthDate);

        final matchesMonth =
            selectedMonth == null || birthMonth == selectedMonth;
        final matchesDay = selectedDay == null ||
            selectedDay == "00" ||
            birthDay == selectedDay;
        final matchesGrade =
            selectedGrade == null || visitor.grade.toString() == selectedGrade;
        final matchesCategory =
            selectedCategory == null || visitor.category == selectedCategory;

        final matchesSearchQuery = visitor.name.contains(searchQuery);

        // Filter by visitor type (boy/girl)
        final matchesVisitorType = selectedVisitorType == null ||
            (selectedVisitorType == 'boy' && visitor.visitorType == 'boy') ||
            (selectedVisitorType == 'girl' && visitor.visitorType == 'girl');

        return matchesMonth &&
            matchesDay &&
            matchesGrade &&
            matchesCategory &&
            matchesSearchQuery &&
            matchesVisitorType; // Add this check
      }).toList();
    });
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
            'أعياد الميلاد',
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
                        searchQuery = value;
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
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedDay = newValue;
                            _filterVisitors();
                          });
                        },
                        items: [
                          const DropdownMenuItem<String>(
                            value: "00",
                            child: Text(
                              'كل الأيام',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...List.generate(31, (index) {
                            return DropdownMenuItem<String>(
                              value: (index + 1).toString().padLeft(2, '0'),
                              child: Text(
                                '${index + 1}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        hint: const Text(
                          'اختر اليوم',
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
                        value: selectedDay,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            selectedMonth = null;
                            selectedDay = null;
                            selectedGrade = null;
                            selectedCategory = null;
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
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: DropdownButton2<String>(
                        value: selectedMonth,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMonth = newValue;
                            _filterVisitors();
                          });
                        },
                        items: List.generate(12, (index) {
                          return DropdownMenuItem<String>(
                            value: (index + 1).toString().padLeft(2, '0'),
                            child: Text(
                              '${index + 1} - ${_getArabicMonth(index + 1)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        hint: const Text(
                          'اختر الشهر',
                          overflow: TextOverflow.ellipsis,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                        isExpanded: true,
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
                        value: selectedGrade,
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
                        isExpanded: true,
                        hint: const Text(
                          'اختر الصف',
                          overflow: TextOverflow.ellipsis,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                      ),
                    ),
                    SizedBox(
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
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                        hint: const Text(
                          'اختر النوع',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: DropdownButton2<String>(
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
                              value == 'unknow' ? '⠀' : value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        isExpanded: true,
                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        iconStyleData: IconStyleData(iconEnabledColor: blue),
                        hint: const Text(
                          'اختر الفئة',
                          overflow: TextOverflow.ellipsis,
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
                ? const Center(child: Text('لا توجد أعياد ميلاد في هذا الشهر'))
                : ListView.builder(
                    itemCount: _filteredVisitors.length,
                    itemBuilder: (context, index) {
                      Visitor visitor = _filteredVisitors[index];
                      String category = visitor.category == 'unknow'
                          ? ''
                          : ' ${visitor.category}';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(
                              '${visitor.name} (سنة ${visitor.grade} ثانوي$category)'),
                          subtitle: Text(
                              'تاريخ الميلاد: ${DateFormat('dd-MM-yyyy').format(visitor.birthDate)}'),
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

  String _getArabicMonth(int month) {
    const months = [
      "يناير",
      "فبراير",
      "مارس",
      "أبريل",
      "مايو",
      "يونيو",
      "يوليو",
      "أغسطس",
      "سبتمبر",
      "أكتوبر",
      "نوفمبر",
      "ديسمبر"
    ];
    return months[month - 1];
  }
}
