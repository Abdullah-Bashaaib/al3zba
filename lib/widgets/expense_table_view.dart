import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ezba_provider.dart';
import '../models/expense_item.dart';
import '../utils/formatters.dart';
import 'add_expense_dialog.dart';

class ExpenseTableView extends StatelessWidget {
  const ExpenseTableView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final period = provider.activePeriod;
    final members = period.members;
    final items = period.items;
    final currency = period.currency;

    if (members.isEmpty) {
      return const Center(
        child: Text('لا يوجد أعضاء في هذا الحساب'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اضغط على أي بند لتعديل التكلفة أو طريقة التقسيم. الجدول مطابق لنموذج PDF.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable PDF-like Table Card
              Card(
                elevation: 1,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth > 0 ? constraints.maxWidth - 26 : 500,
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFF2563EB), // PDF Blue Header
                      ),
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 52,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'RB',
                      ),
                      horizontalMargin: 12,
                      columnSpacing: 16,
                      border: TableBorder.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      columns: [
                        const DataColumn(
                          label: Text('البند', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const DataColumn(
                          numeric: true,
                          label: Text('التكلفة', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...members.map((member) => DataColumn(
                              numeric: true,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (member.isHouseFund)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.home, size: 14, color: Colors.amberAccent),
                                    ),
                                  Text(member.name),
                                ],
                              ),
                            )),
                      ],
                      rows: [
                        // Data rows
                        ...items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final isEven = idx % 2 == 0;
                          final rowBgColor = isEven ? Colors.white : const Color(0xFFF8FAFC);

                          return DataRow(
                            color: WidgetStateProperty.all(rowBgColor),
                            onSelectChanged: (_) {
                              _showEditItemDialog(context, item);
                            },
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: () => _showQuickCostDialog(context, item, currency),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.totalCost > 0
                                          ? const Color(0xFFEFF6FF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      EzbaFormatters.formatCurrency(item.totalCost, currency),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: item.totalCost > 0
                                            ? const Color(0xFF1D4ED8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ...members.map((member) {
                                final share = item.getShareForMember(member.id, members);
                                return DataCell(
                                  Text(
                                    EzbaFormatters.formatCurrency(share, currency),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: share > 0
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF94A3B8),
                                      fontWeight:
                                          share > 0 ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                        // Total Row (Matching PDF style)
                        DataRow(
                          color: WidgetStateProperty.all(const Color(0xFF1E3A8A)),
                          cells: [
                            const DataCell(
                              Text(
                                'الإجمالي',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                EzbaFormatters.formatCurrency(period.totalExpenses, currency),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ...members.map((member) {
                              final totalShare = period.getMemberTotalShare(member.id);
                              return DataCell(
                                Text(
                                  EzbaFormatters.formatCurrency(totalShare, currency),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 12.5,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (items.isEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'لا توجد بنود مصاريف مضافة حالياً',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'تم تصفير الجدول بنجاح. يمكنك الآن البدء بإضافة بنود الصرف وتحديد تكلفتها.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const AddExpenseDialog(),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة بند صرف جديد'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showQuickCostDialog(BuildContext context, ExpenseItem item, String currency) {
    final controller = TextEditingController(
      text: item.totalCost > 0 ? item.totalCost.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل تكلفة ${item.title}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'المبلغ الإجمالي ($currency)',
            hintText: '0',
            prefixIcon: const Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final cost = double.tryParse(controller.text) ?? 0.0;
              context.read<EzbaProvider>().updateItemCost(item.id, cost);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, ExpenseItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AddExpenseDialog(itemToEdit: item),
    );
  }
}
