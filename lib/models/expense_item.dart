import 'member.dart';

enum SplitType {
  equalAll, // مقسم بالتساوي على جميع الأعضاء
  equalSelected, // مقسم بالتساوي على أعضاء محددين
  customAmounts, // مبالغ مخصصة لكل عضو
}

class ExpenseItem {
  final String id;
  final String title; // مثل: الراشن، الكهرباء، الماء، الغاز، صيانة البيت، أخرى
  final double totalCost; // التكلفة الإجمالية
  final SplitType splitType;
  final List<String> includedMemberIds; // للأعضاء المحددين عند التقسيم
  final Map<String, double> customShares; // {memberId: shareAmount}
  final String? paidByMemberId; // من دفع المبلغ (null = لم يحدد / الصندوق)
  final String? notes;
  final DateTime? date;

  const ExpenseItem({
    required this.id,
    required this.title,
    this.totalCost = 0.0,
    this.splitType = SplitType.equalAll,
    this.includedMemberIds = const [],
    this.customShares = const {},
    this.paidByMemberId,
    this.notes,
    this.date,
  });

  /// Calculate share for a specific member
  double getShareForMember(String memberId, List<Member> allMembers) {
    if (totalCost <= 0) return 0.0;

    switch (splitType) {
      case SplitType.equalAll:
        if (allMembers.isEmpty) return 0.0;
        return totalCost / allMembers.length;

      case SplitType.equalSelected:
        final membersCount = includedMemberIds.isEmpty
            ? allMembers.length
            : includedMemberIds.length;
        if (membersCount == 0) return 0.0;
        if (includedMemberIds.isEmpty || includedMemberIds.contains(memberId)) {
          return totalCost / membersCount;
        }
        return 0.0;

      case SplitType.customAmounts:
        return customShares[memberId] ?? 0.0;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'totalCost': totalCost,
        'splitType': splitType.name,
        'includedMemberIds': includedMemberIds,
        'customShares': customShares,
        'paidByMemberId': paidByMemberId,
        'notes': notes,
        'date': date?.toIso8601String(),
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
        id: json['id'] as String,
        title: json['title'] as String,
        totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
        splitType: SplitType.values.firstWhere(
          (e) => e.name == json['splitType'],
          orElse: () => SplitType.equalAll,
        ),
        includedMemberIds: (json['includedMemberIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        customShares: (json['customShares'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            const {},
        paidByMemberId: json['paidByMemberId'] as String?,
        notes: json['notes'] as String?,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String)
            : null,
      );

  ExpenseItem copyWith({
    String? id,
    String? title,
    double? totalCost,
    SplitType? splitType,
    List<String>? includedMemberIds,
    Map<String, double>? customShares,
    String? paidByMemberId,
    String? notes,
    DateTime? date,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      totalCost: totalCost ?? this.totalCost,
      splitType: splitType ?? this.splitType,
      includedMemberIds: includedMemberIds ?? this.includedMemberIds,
      customShares: customShares ?? this.customShares,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }
}
