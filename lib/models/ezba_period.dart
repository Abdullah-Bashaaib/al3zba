import 'member.dart';
import 'expense_item.dart';
import 'settlement.dart';

class EzbaPeriod {
  final String id;
  final String title; // مثل "حساب شهر سبتمبر 2026" أو "حساب العزبة"
  final String currency; // "YER" / "ر.ي"
  final List<Member> members;
  final List<ExpenseItem> items;
  final DateTime createdAt;
  final bool isArchived;

  EzbaPeriod({
    required this.id,
    required this.title,
    this.currency = 'YER',
    required this.members,
    required this.items,
    DateTime? createdAt,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Total sum of all expense items
  double get totalExpenses =>
      items.fold(0.0, (sum, item) => sum + item.totalCost);

  /// Calculate total cost assigned to a member across all items
  double getMemberTotalShare(String memberId) {
    return items.fold(
      0.0,
      (sum, item) => sum + item.getShareForMember(memberId, members),
    );
  }

  /// Calculate total amount paid by a member for expenses
  double getMemberTotalPaid(String memberId) {
    return items
        .where((item) => item.paidByMemberId == memberId)
        .fold(0.0, (sum, item) => sum + item.totalCost);
  }

  /// Calculate net balance for a member (Positive = Person is owed money, Negative = Person owes money)
  double getMemberNetBalance(String memberId) {
    final paid = getMemberTotalPaid(memberId);
    final share = getMemberTotalShare(memberId);
    final member = members.firstWhere(
      (m) => m.id == memberId,
      orElse: () => Member(id: memberId, name: ''),
    );
    return (paid - share) + member.initialBalance;
  }

  /// Calculate optimized settlements between members to clear debts
  List<Settlement> calculateSettlements() {
    // Balances: positive means creditor (needs to receive), negative means debtor (needs to pay)
    final Map<String, double> balances = {};
    for (final member in members) {
      final net = getMemberNetBalance(member.id);
      if (net.abs() > 0.01) {
        balances[member.id] = net;
      }
    }

    final List<Settlement> settlements = [];
    final List<MapEntry<String, double>> debtors = [];
    final List<MapEntry<String, double>> creditors = [];

    balances.forEach((id, bal) {
      if (bal < -0.01) {
        debtors.add(MapEntry(id, -bal)); // positive debt amount
      } else if (bal > 0.01) {
        creditors.add(MapEntry(id, bal));
      }
    });

    int dIdx = 0;
    int cIdx = 0;

    while (dIdx < debtors.length && cIdx < creditors.length) {
      final debtor = debtors[dIdx];
      final creditor = creditors[cIdx];

      final dMember = members.firstWhere((m) => m.id == debtor.key);
      final cMember = members.firstWhere((m) => m.id == creditor.key);

      final minAmount = debtor.value < creditor.value ? debtor.value : creditor.value;

      if (minAmount > 0.01) {
        settlements.add(Settlement(
          fromMemberId: dMember.id,
          fromMemberName: dMember.name,
          toMemberId: cMember.id,
          toMemberName: cMember.name,
          amount: minAmount,
        ));
      }

      debtors[dIdx] = MapEntry(debtor.key, debtor.value - minAmount);
      creditors[cIdx] = MapEntry(creditor.key, creditor.value - minAmount);

      if (debtors[dIdx].value < 0.01) {
        dIdx++;
      }
      if (creditors[cIdx].value < 0.01) {
        cIdx++;
      }
    }

    return settlements;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'currency': currency,
        'members': members.map((m) => m.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isArchived': isArchived,
      };

  factory EzbaPeriod.fromJson(Map<String, dynamic> json) => EzbaPeriod(
        id: json['id'] as String,
        title: json['title'] as String,
        currency: json['currency'] as String? ?? 'YER',
        members: (json['members'] as List<dynamic>)
            .map((m) => Member.fromJson(m as Map<String, dynamic>))
            .toList(),
        items: (json['items'] as List<dynamic>)
            .map((i) => ExpenseItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isArchived: json['isArchived'] as bool? ?? false,
      );

  /// Default initial period with clean members and empty items
  static EzbaPeriod createDefault() {
    final members = [
      const Member(id: 'house', name: 'البيت', isHouseFund: true),
      const Member(id: 'munir', name: 'منير'),
      const Member(id: 'salem', name: 'سالم'),
      const Member(id: 'majdi', name: 'مجدي'),
    ];

    return EzbaPeriod(
      id: 'period_default',
      title: 'حساب العزبة',
      currency: 'YER',
      members: members,
      items: const [],
      createdAt: DateTime.now(),
    );
  }

  EzbaPeriod copyWith({
    String? id,
    String? title,
    String? currency,
    List<Member>? members,
    List<ExpenseItem>? items,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return EzbaPeriod(
      id: id ?? this.id,
      title: title ?? this.title,
      currency: currency ?? this.currency,
      members: members ?? this.members,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
