import 'package:intl/intl.dart';

class Visitor {
  final int? id;
  final String name;
  final DateTime birthDate;
  final int grade;
  final String category;
  final String fatherName;
  final String responsiblePriest;
  final String region;
  final DateTime? lastVisit;
  final String visitorType;

  Visitor({
    this.id,
    required this.name,
    required this.birthDate,
    required this.grade,
    required this.category,
    required this.fatherName,
    required this.responsiblePriest,
    required this.region,
    this.lastVisit,
    required this.visitorType, 
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
      'grade': grade,
      'category': category,
      'fatherName': fatherName,
      'responsiblePriest': responsiblePriest,
      'region': region,
      'lastVisit': lastVisit != null
          ? DateFormat('yyyy-MM-dd').format(lastVisit!)
          : null,
      'visitorType': visitorType,
    };
  }

  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      id: map['id'],
      name: map['name'],
      birthDate: DateTime.parse(map['birthDate']),
      grade: map['grade'],
      category: map['category'],
      fatherName: map['fatherName'],
      responsiblePriest: map['responsiblePriest'],
      region: map['region'],
      lastVisit: map['lastVisit'] != null ? DateTime.parse(map['lastVisit']) : null,
      visitorType: map['visitorType'],
    );
  }
}
