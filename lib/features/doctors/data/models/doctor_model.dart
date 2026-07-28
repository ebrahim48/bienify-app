import '../../domain/entities/doctor.dart';

/// Serialisation layer for [Doctor].
class DoctorModel extends Doctor {
  const DoctorModel({
    required super.id,
    required super.name,
    required super.specialty,
    super.photoUrl,
    super.rating,
    super.reviewCount,
    super.consultationFee,
    super.isAvailable,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'specialty': specialty,
    'photo_url': photoUrl,
    'rating': rating,
    'review_count': reviewCount,
    'consultation_fee': consultationFee,
    'is_available': isAvailable,
  };
}
