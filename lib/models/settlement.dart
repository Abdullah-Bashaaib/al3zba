class Settlement {
  final String fromMemberId;
  final String fromMemberName;
  final String toMemberId;
  final String toMemberName;
  final double amount;

  const Settlement({
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amount,
  });
}

/// تسوية مفصّلة لكل بند — يدفع fromMember لـ toMember مبلغ amount بسبب بند itemTitle
class ItemSettlement {
  final String fromMemberId;
  final String fromMemberName;
  final String toMemberId;
  final String toMemberName;
  final double amount;
  final String itemTitle;

  const ItemSettlement({
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amount,
    required this.itemTitle,
  });
}

/// ملخص ما يدفعه عضو واحد مجمّعًا (الإجمالي + التفاصيل البندية)
class MemberPaymentSummary {
  final String memberId;
  final String memberName;
  final double totalToPay;
  final List<ItemSettlement> breakdowns;

  const MemberPaymentSummary({
    required this.memberId,
    required this.memberName,
    required this.totalToPay,
    required this.breakdowns,
  });
}
