import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/ezba_provider.dart';
import '../utils/formatters.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/expense_cards_view.dart';
import '../widgets/expense_table_view.dart';
import '../widgets/manage_members_dialog.dart';
import '../widgets/members_summary_view.dart';
import '../widgets/period_selector_sheet.dart';
import '../widgets/settlement_view.dart';
import 'pdf_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final period = provider.activePeriod;
    final currency = period.currency;
    final memberCount = period.members.length;
    final avgShare = memberCount > 0 ? period.totalExpenses / memberCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const PeriodSelectorSheet(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    period.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ),
        actions: [
          // PDF Export Button
          IconButton(
            tooltip: 'معاينة وتصدير PDF',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PdfPreviewScreen()),
              );
            },
          ),
          // WhatsApp / Text Share Button
          IconButton(
            tooltip: 'مشاركة التقرير',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.share,
                color: Color(0xFF16A34A),
                size: 20,
              ),
            ),
            onPressed: () => _showShareDialog(context, provider),
          ),
          // More Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF475569)),
            onSelected: (val) {
              if (val == 'members') {
                showDialog(
                  context: context,
                  builder: (_) => const ManageMembersDialog(),
                );
              } else if (val == 'currency') {
                _showCurrencyDialog(context, provider);
              } else if (val == 'reset') {
                _confirmResetItems(context, provider);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 20,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 8),
                    Text('إدارة الأعضاء'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'currency',
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      size: 20,
                      color: Color(0xFF0D9488),
                    ),
                    SizedBox(width: 8),
                    Text('تغيير العملة'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.cleaning_services_outlined,
                      size: 20,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 8),
                    Text('تصفير وحذف جميع البنود'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Summary Banner
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إجمالي مصاريف العزبة',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        EzbaFormatters.formatDate(period.createdAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    EzbaFormatters.formatCurrency(
                      period.totalExpenses,
                      currency,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$memberCount أعضاء / حصص',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.pie_chart_outline,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'المتوسط: ${EzbaFormatters.formatCurrency(avgShare, currency)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'RB',
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                fontFamily: 'RB',
              ),
              tabs: const [
                Tab(
                  text: 'جدول الـ PDF',
                  icon: Icon(Icons.table_chart, size: 18),
                ),
                Tab(text: 'البنود', icon: Icon(Icons.receipt_long, size: 18)),
                Tab(text: 'الأعضاء', icon: Icon(Icons.people_alt, size: 18)),
                Tab(text: 'التسوية', icon: Icon(Icons.sync_alt, size: 18)),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ExpenseTableView(),
                ExpenseCardsView(),
                MembersSummaryView(),
                SettlementView(),
              ],
            ),
          ),
          SizedBox(height: (MediaQuery.viewPaddingOf(context).bottom) + 60),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddExpenseDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة بند مصروف'),
      ),
    );
  }

  void _showShareDialog(BuildContext context, EzbaProvider provider) {
    final summaryText = provider.generateWhatsAppSummary();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('مشاركة كشف الحساب'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SelectableText(
                summaryText,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Courier',
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summaryText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ النص بنجاح')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('نسخ النص'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Share.share(summaryText, subject: 'كشف حساب مصاريف العزبة');
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('مشاركة واتساب'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, EzbaProvider provider) {
    final currencies = ['YER', 'SAR', 'USD', 'AED', 'EGP', 'OMR', 'KWD', 'QAR'];
    final current = provider.currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختيار رمز العملة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (c, idx) {
              final curr = currencies[idx];
              final isSelected = curr == current;
              return ListTile(
                title: Text(
                  curr,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  provider.updateCurrency(curr);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmResetItems(BuildContext context, EzbaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_outlined, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('تصفير وحذف جميع البنود'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف وتصفير جميع بنود الصرف في هذه الفترة؟\nستتمكن بعدها من إضافة بنودك الخاصة من جديد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.resetToPdfDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تصفير وحذف جميع بنود الصرف بنجاح'),
                ),
              );
            },
            child: const Text('تصفير وحذف'),
          ),
        ],
      ),
    );
  }
}
