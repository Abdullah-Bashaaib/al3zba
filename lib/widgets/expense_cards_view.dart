import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ezba_provider.dart';
import '../models/expense_item.dart';
import '../models/member.dart';
import '../utils/formatters.dart';
import 'add_expense_dialog.dart';

class ExpenseCardsView extends StatelessWidget {
  const ExpenseCardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final items = provider.items;
    final members = provider.members;
    final currency = provider.currency;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'لا توجد بنود مصاريف حتى الآن',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddExpenseDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة بند جديد'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final payer = item.paidByMemberId != null
            ? members.firstWhere(
                (m) => m.id == item.paidByMemberId,
                orElse: () => const Member(id: '', name: 'غير معروف'),
              )
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AddExpenseDialog(itemToEdit: item),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Total Cost Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Icon(
                          _getIconForItem(item.title),
                          color: const Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (payer != null)
                              Text(
                                'دفعه: ${payer.name}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0D9488),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            EzbaFormatters.formatCurrency(item.totalCost, currency),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.totalCost > 0
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _getSplitDescription(item, members),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Breakdown per member
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: members.map((m) {
                      final share = item.getShareForMember(m.id, members);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: share > 0
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: share > 0
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          '${m.name}: ${EzbaFormatters.formatAmount(share)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: share > 0 ? FontWeight.w600 : FontWeight.normal,
                            color: share > 0
                                ? const Color(0xFF334155)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForItem(String title) {
    if (title.contains('راشن') || title.contains('أكل') || title.contains('طعام')) {
      return Icons.shopping_basket_outlined;
    }
    if (title.contains('كهرباء') || title.contains('كهربا')) {
      return Icons.electric_bolt_outlined;
    }
    if (title.contains('ماء') || title.contains('مياه')) {
      return Icons.water_drop_outlined;
    }
    if (title.contains('غاز')) {
      return Icons.local_fire_department_outlined;
    }
    if (title.contains('صيانة') || title.contains('بيت')) {
      return Icons.home_repair_service_outlined;
    }
    if (title.contains('إنترنت') || title.contains('نت')) {
      return Icons.wifi;
    }
    if (title.contains('خضار') || title.contains('فواكه')) {
      return Icons.eco_outlined;
    }
    if (title.contains('لحم') || title.contains('دجاج')) {
      return Icons.restaurant;
    }
    return Icons.receipt_outlined;
  }

  String _getSplitDescription(ExpenseItem item, List<Member> members) {
    switch (item.splitType) {
      case SplitType.equalAll:
        return 'مقسم بالتساوي على ${members.length}';
      case SplitType.equalSelected:
        final count = item.includedMemberIds.isEmpty ? members.length : item.includedMemberIds.length;
        return 'مقسم على $count محددين';
      case SplitType.customAmounts:
        return 'تقسيم مخصص';
    }
  }
}
