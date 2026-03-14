/// 利用者プロフィール [DE-01]
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.birthDate,
    this.sex = Sex.unspecified,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime? birthDate;
  final Sex sex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile copyWith({
    String? name,
    DateTime? birthDate,
    Sex? sex,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// 性別
enum Sex {
  male('男性'),
  female('女性'),
  other('その他'),
  unspecified('未指定');

  const Sex(this.label);
  final String label;
}
