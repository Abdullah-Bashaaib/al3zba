import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ezba_provider.dart';
import '../utils/formatters.dart';
import 'manage_members_dialog.dart';

class MembersSummaryView extends StatelessWidget {
  const MembersSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final period = provider.activePeriod;
    final members = period.members;
    final currency = period.currency;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Manage Members Action Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حسابات الأعضاء (${members.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ManageMembersDialog(),
                  );
                },
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('إدارة الأعضاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Member Cards
          ...members.map((member) {
            final share = period.getMemberTotalShare(member.id);
            final paid = period.getMemberTotalPaid(member.id);
            final net = period.getMemberNetBalance(member.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Member Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: member.isHouseFund
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDBEAFE),
                          child: Icon(
                            member.isHouseFund ? Icons.home : Icons.person,
                            color: member.isHouseFund
                                ? const Color(0xFFD97706)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (member.isHouseFund) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'حساب البيت',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF92400E),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                'نسبة من إجمالي المصاريف: ${period.totalExpenses > 0 ? ((share / period.totalExpenses) * 100).toStringAsFixed(1) : '0'}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildNetBadge(net, currency),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Financial metrics grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            title: 'إجمالي النصيب',
                            amount: EzbaFormatters.formatCurrency(share, currency),
                            icon: Icons.receipt,
                            iconColor: const Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          height: 36,
                          width: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            title: 'إجمالي ما دفعه',
                            amount: EzbaFormatters.formatCurrency(paid, currency),
                            icon: Icons.payments_outlined,
                            iconColor: const Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetBadge(double net, String currency) {
    if (net.abs() < 0.01) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Text(
          'خالص الحساب',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      );
    }

    final isPositive = net > 0;
    final bgColor = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final textColor = isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final borderColor = isPositive ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
    final label = isPositive
        ? 'له: +${EzbaFormatters.formatCurrency(net, currency)}'
        : 'عليه: ${EzbaFormatters.formatCurrency(net.abs(), currency)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
