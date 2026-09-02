import 'package:flutter_test/flutter_test.dart';
import 'package:al3zba/models/ezba_period.dart';
import 'package:al3zba/models/expense_item.dart';
import 'package:al3zba/models/member.dart';

void main() {
  group('Ezba Calculations & Split Tests', () {
    test('Default period creates clean members and starts with empty items', () {
      final period = EzbaPeriod.createDefault();

      // Verify members matching PDF: البيت, منير, سالم, مجدي
      expect(period.members.length, 4);
      expect(period.members.map((m) => m.name).toList(), [
        'البيت',
        'منير',
        'سالم',
        'مجدي',
      ]);

      // Starts with zero/empty items so user can add custom items
      expect(period.items.isEmpty, true);
      expect(period.totalExpenses, 0.0);
    });

    test('Adding custom items and equal split calculation', () {
      final period = EzbaPeriod.createDefault();
      final rationItem = const ExpenseItem(
        id: 'ration',
        title: 'الراشن',
        totalCost: 135000.0,
        splitType: SplitType.equalAll,
      );

      final updatedPeriod = period.copyWith(items: [rationItem]);

      // Verify total expenses = 135,000 YER
      expect(updatedPeriod.totalExpenses, 135000.0);

      // Verify each member share is exactly 33,750 YER (135,000 / 4)
      for (final member in updatedPeriod.members) {
        final share = rationItem.getShareForMember(member.id, updatedPeriod.members);
        expect(share, 33750.0);

        final totalShare = updatedPeriod.getMemberTotalShare(member.id);
        expect(totalShare, 33750.0);
      }
    });

    test('Custom split and selective split calculations', () {
      final members = [
        const Member(id: '1', name: 'أحمد'),
        const Member(id: '2', name: 'خالد'),
        const Member(id: '3', name: 'طارق'),
      ];

      // Item split only between أحمد and خالد (60,000 / 2 = 30,000 each)
      final selectiveItem = const ExpenseItem(
        id: 'i1',
        title: 'فاتورة إنترنت',
        totalCost: 60000.0,
        splitType: SplitType.equalSelected,
        includedMemberIds: ['1', '2'],
      );

      expect(selectiveItem.getShareForMember('1', members), 30000.0);
      expect(selectiveItem.getShareForMember('2', members), 30000.0);
      expect(selectiveItem.getShareForMember('3', members), 0.0);

      // Custom shares
      final customItem = const ExpenseItem(
        id: 'i2',
        title: 'أغراض خاصة',
        totalCost: 10000.0,
        splitType: SplitType.customAmounts,
        customShares: {
          '1': 6000.0,
          '2': 4000.0,
          '3': 0.0,
        },
      );

      expect(customItem.getShareForMember('1', members), 6000.0);
      expect(customItem.getShareForMember('2', members), 4000.0);
      expect(customItem.getShareForMember('3', members), 0.0);
    });

    test('Settlement calculations when one member pays for all', () {
      final members = [
        const Member(id: 'house', name: 'البيت'),
        const Member(id: 'munir', name: 'منير'),
        const Member(id: 'salem', name: 'سالم'),
        const Member(id: 'majdi', name: 'مجدي'),
      ];

      // Majdi paid 135,000 for ration
      final items = [
        const ExpenseItem(
          id: 'ration',
          title: 'الراشن',
          totalCost: 135000.0,
          splitType: SplitType.equalAll,
          paidByMemberId: 'majdi',
        ),
      ];

      final period = EzbaPeriod(
        id: 'test',
        title: 'حساب تجريبي',
        members: members,
        items: items,
      );

      // Majdi paid 135,000 and his share is 33,750 -> Net balance = +101,250 (له)
      expect(period.getMemberNetBalance('majdi'), 101250.0);

      // Others paid 0 and their share is 33,750 -> Net balance = -33,750 (عليهم)
      expect(period.getMemberNetBalance('house'), -33750.0);
      expect(period.getMemberNetBalance('munir'), -33750.0);
      expect(period.getMemberNetBalance('salem'), -33750.0);

      // Verify settlements
      final settlements = period.calculateSettlements();
      expect(settlements.length, 3);

      for (final s in settlements) {
        expect(s.toMemberName, 'مجدي');
        expect(s.amount, 33750.0);
      }
    });
  });
}
