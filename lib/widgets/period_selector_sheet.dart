import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ezba_provider.dart';
import '../models/ezba_period.dart';
import '../utils/formatters.dart';

class PeriodSelectorSheet extends StatelessWidget {
  const PeriodSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final periods = provider.periods;
    final activeId = provider.activePeriodId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الفترات والأشهر المحفوظة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewPeriodDialog(context, provider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('فترة جديدة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // List of Periods
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: periods.length,
              itemBuilder: (context, index) {
                final period = periods[index];
                final isActive = period.id == activeId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    onTap: () {
                      provider.setActivePeriod(period.id);
                      Navigator.pop(context);
                    },
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      child: Icon(
                        Icons.calendar_month,
                        color: isActive ? Colors.white : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      period.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      'الإجمالي: ${EzbaFormatters.formatCurrency(period.totalExpenses, period.currency)} • ${period.members.length} أعضاء',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showRenamePeriodDialog(context, provider, period),
                        ),
                        if (periods.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () => _confirmDeletePeriod(context, provider, period),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Reset / Clear items button
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              provider.resetToPdfDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تصفير وحذف جميع بنود الصرف بنجاح')),
              );
            },
            icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: Color(0xFFDC2626)),
            label: const Text(
              'تصفير وحذف جميع بنود الصرف',
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewPeriodDialog(BuildContext context, EzbaProvider provider) {
    final controller = TextEditingController(
      text: 'حساب شهر ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنشاء فترة / شهر جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'اسم الفترة أو الشهر',
                hintText: 'مثال: حساب شهر أكتوبر 2026',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'سيتم نسخ الأعضاء الحاليين وتجهيز بنود المصاريف الافتراضية للفترة الجديدة.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createNewPeriod(controller.text.trim());
              }
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showRenamePeriodDialog(BuildContext context, EzbaProvider provider, EzbaPeriod period) {
    final controller = TextEditingController(text: period.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل اسم الفترة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'اسم الفترة'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updatePeriodTitle(period.id, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePeriod(BuildContext context, EzbaProvider provider, EzbaPeriod period) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفترة'),
        content: Text('هل أنت متأكد من حذف "${period.title}"؟ لا يمكن التراجع عن هذه الخطوة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deletePeriod(period.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }
}
