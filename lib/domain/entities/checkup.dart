/// 健診受診記録 [DE-02]
class Checkup {
  const Checkup({
    required this.id,
    required this.profileId,
    required this.date,
    this.facilityName,
    this.sourceImagePath,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final DateTime date;
  final String? facilityName;
  final String? sourceImagePath;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Checkup copyWith({
    String? facilityName,
    String? sourceImagePath,
    String? memo,
    DateTime? updatedAt,
  }) {
    return Checkup(
      id: id,
      profileId: profileId,
      date: date,
      facilityName: facilityName ?? this.facilityName,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      memo: memo ?? this.memo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
