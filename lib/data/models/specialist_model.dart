import '../../domain/entities/specialist.dart';

class SpecialistModel extends Specialist {
  const SpecialistModel({
    required super.id,
    required super.fullName,
    required super.role,
    super.profileImage,
    super.biography,
    super.specialties,
    super.qualifications,
    super.yearsOfExperience,
    super.languagesSpoken,
  });

  factory SpecialistModel.fromJson(Map<String, dynamic> json) {
    final roleVal = json['role'];
    String roleName = '';
    if (roleVal is Map) {
      roleName = roleVal['name']?.toString() ?? '';
    } else if (roleVal != null) {
      roleName = roleVal.toString();
    }

    List<String>? parseStringList(dynamic listVal) {
      if (listVal is List) {
        return listVal.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return null;
    }

    int? parseToInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return SpecialistModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      role: roleName,
      profileImage: json['profileImage']?.toString(),
      biography: json['biography']?.toString(),
      specialties: parseStringList(json['specialties']),
      qualifications: parseStringList(json['qualifications']),
      yearsOfExperience: parseToInt(json['yearsOfExperience']),
      languagesSpoken: parseStringList(json['languagesSpoken']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'role': role,
      'profileImage': profileImage,
      'biography': biography,
      'specialties': specialties,
      'qualifications': qualifications,
      'yearsOfExperience': yearsOfExperience,
      'languagesSpoken': languagesSpoken,
    };
  }

  Specialist toEntity() {
    return Specialist(
      id: id,
      fullName: fullName,
      role: role,
      profileImage: profileImage,
      biography: biography,
      specialties: specialties,
      qualifications: qualifications,
      yearsOfExperience: yearsOfExperience,
      languagesSpoken: languagesSpoken,
    );
  }
}
