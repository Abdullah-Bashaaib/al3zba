import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/ezba_provider.dart';
import '../models/settlement.dart';
import '../utils/formatters.dart';

class SettlementView extends StatelessWidget {
  const SettlementView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final period = provider.activePeriod;
    final settlements = period.calculateSettlements();
    final detailed = period.calculateDetailedSettlements();
    final currency = period.currency;

    if (settlements.isEmpty && detailed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'جميع الحسابات مصفّاة وخالصة!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'لا توجد أي مبالغ مستحقة أو ديون معلقة بين الأعضاء في هذه الفترة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── قسم 1: خلاصة سريعة ────────────────────────────────────────
          _SectionHeader(
            icon: Icons.summarize_outlined,
            color: const Color(0xFF0F766E),
            title: 'خلاصة ما سيدفعه كل طرف ولمن',
            subtitle: 'ملخص مجمّع بالإجمالي والتفاصيل البندية',
          ),
          const SizedBox(height: 8),

          ...detailed.map((summary) {
            return _MemberSummaryCard(
              summary: summary,
              currency: currency,
            );
          }),

          const SizedBox(height: 20),

          // ─── قسم 2: خطة التسوية المُحسّنة ──────────────────────────────
          _SectionHeader(
            icon: Icons.sync_alt,
            color: const Color(0xFF2563EB),
            title: 'خطة التسوية السريعة (أقل تحويلات)',
            subtitle:
                'تم حساب أقل عدد تحويلات مطلوب (${settlements.length} تحويلات) لتصفية كافة حسابات العزبة.',
          ),
          const SizedBox(height: 8),

          ...settlements.map((s) => _TransferCard(s: s, currency: currency)),

          const SizedBox(height: 12),

          // ─── زر نسخ ─────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () {
              final text = _buildCopyText(detailed, settlements, currency);
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ خطة التسوية بنجاح ✅')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('نسخ تفاصيل التسوية الكاملة'),
          ),
        ],
      ),
    );
  }

  String _buildCopyText(
    List<MemberPaymentSummary> detailed,
    List<Settlement> settlements,
    String currency,
  ) {
    final buf = StringBuffer();
    buf.writeln('✍🏼 خلاصة ما سيدفعه كل طرف ولمن ..\n');

    for (final s in detailed) {
      buf.writeln(
        '> طرف أهل ${s.memberName} ( ${EzbaFormatters.formatCurrency(s.totalToPay, currency)} )',
      );
      int idx = 1;
      for (final b in s.breakdowns) {
        buf.writeln(
          '$idx. ${b.itemTitle} = ${EzbaFormatters.formatCurrency(b.amount, currency)} لـ ${b.toMemberName}',
        );
        idx++;
      }
      buf.writeln();
    }

    buf.writeln('\n─── خطة التسوية السريعة ───');
    for (final t in settlements) {
      buf.writeln(
        '• ${t.fromMemberName} يدفع لـ ${t.toMemberName}: ${EzbaFormatters.formatCurrency(t.amount, currency)}',
      );
    }
    return buf.toString();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widgets مساعدة
// ──────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة ملخص عضو واحد مع تفاصيل البنود — يشبه تنسيق الرسالة
class _MemberSummaryCard extends StatelessWidget {
  final MemberPaymentSummary summary;
  final String currency;

  const _MemberSummaryCard({required this.summary, required this.currency});

  @override
  Widget build(BuildContext context) {
    // هل الإجمالي صفر (منير في المثال)
    final isZero = summary.totalToPay < 0.01;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── رأس البطاقة ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isZero
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFF7ED),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isZero
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFEA580C),
                  child: Text(
                    summary.memberName.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طرف أهل ${summary.memberName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isZero ? 'لا يوجد عليه شيء ✅' : 'إجمالي ما عليه',
                        style: TextStyle(
                          fontSize: 11,
                          color: isZero
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isZero
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    EzbaFormatters.formatCurrency(summary.totalToPay, currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── تفاصيل البنود ───
          if (!isZero)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: List.generate(summary.breakdowns.length, (idx) {
                  final b = summary.breakdowns[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // رقم البند
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // اسم البند
                        Expanded(
                          child: Text(
                            b.itemTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),

                        // السهم "لـ من"
                        Text(
                          'لـ ${b.toMemberName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // المبلغ
                        Text(
                          EzbaFormatters.formatCurrency(b.amount, currency),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// بطاقة تحويل إجمالي واحد (خطة التسوية السريعة)
class _TransferCard extends StatelessWidget {
  final Settlement s;
  final String currency;

  const _TransferCard({required this.s, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // من
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'يدفع',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.fromMemberName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            // المبلغ + سهم
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      EzbaFormatters.formatCurrency(s.amount, currency),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'تحويل إلى',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // لـ
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'يستلم',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.toMemberName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
