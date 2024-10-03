import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visitation/Colors/color.dart';
import '../helpers/database_helper.dart';
import '../models/visitor.dart';
import 'edit_visitor_screen.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  EditScreenState createState() => EditScreenState();
}

class EditScreenState extends State<EditScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadVisitors();
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
            (selectedVisitorType == 'boy' &&
                visitor.visitorType == 'boy') ||
            (selectedVisitorType == 'girl' &&
                visitor.visitorType == 'girl');

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

  void _deleteVisitor(int id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'تحذير',
            style: TextStyle(color: red),
          ),
          content: Text('هل أنت متأكد أنك تريد حذف "$name"؟'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'لا',
                style: TextStyle(color: white),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await _databaseHelper.deleteVisitor(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: blue,
                    content: Text(
                      'تم حذف "$name"',
                      style: TextStyle(color: white),
                    ),
                  ),
                );
                _loadVisitors();
                Navigator.of(context).pop();
              },
              child: Text(
                'نعم',
                style: TextStyle(color: white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editVisitor(Visitor visitor) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditVisitorScreen(visitor: visitor)),
    ).then((updated) {
      if (updated == true) {
        _loadVisitors();
      }
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
            'تعديل البيانات',
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
                      final visitor = _filteredVisitors[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                            title: Text(
                              '${visitor.name} (${visitor.grade} ثانوي ${visitor.category})',
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تاريخ الميلاد: ${DateFormat('dd-MM-yyyy').format(visitor.birthDate)}',
                                    ),
                                    Text(
                                      '${visitor.fatherName} -  ${visitor.responsiblePriest}',
                                    ),
                                    Text(
                                      'المنطقة: ${visitor.region}',
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: blue,
                                      ),
                                      onPressed: () => _editVisitor(visitor),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: red,
                                      ),
                                      onPressed: () => _deleteVisitor(
                                          visitor.id!, visitor.name),
                                    ),
                                  ],
                                ),
                              ],
                            )),
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
