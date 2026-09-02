class Member {
  final String id;
  final String name;
  final bool isHouseFund; // e.g. "البيت" (Common House Fund)
  final double initialBalance;

  const Member({
    required this.id,
    required this.name,
    this.isHouseFund = false,
    this.initialBalance = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isHouseFund': isHouseFund,
    'initialBalance': initialBalance,
  };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id'] as String,
    name: json['name'] as String,
    isHouseFund: json['isHouseFund'] as bool? ?? false,
    initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
  );

  Member copyWith({
    String? id,
    String? name,
    bool? isHouseFund,
    double? initialBalance,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      isHouseFund: isHouseFund ?? this.isHouseFund,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
