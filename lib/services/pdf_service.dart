import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/ezba_period.dart';
import '../utils/formatters.dart';

class PdfService {
  /// Generate a PDF Document matching the exact layout and design of the reference PDF
  static Future<Uint8List> generateEzbaPdf(EzbaPeriod period) async {
    final pdf = pw.Document();

    // Load RB Arabic font from local assets
    final fontRegularBytes = await rootBundle.load(
      'assets/font/rb-regular.ttf',
    );
    final fontBoldBytes = await rootBundle.load('assets/font/rb-bold.ttf');

    final fontBase = pw.Font.ttf(fontRegularBytes);
    final fontBold = pw.Font.ttf(fontBoldBytes);

    final theme = pw.ThemeData.withFont(base: fontBase, bold: fontBold);

    // Primary table colors matching the reference PDF
    const headerBgColor = PdfColor.fromInt(0xFF2B78E4); // Classic bright blue
    const alternateRowColor = PdfColor.fromInt(0xFFF0F6FF);
    const borderColor = PdfColor.fromInt(0xFFE2E8F0);
    const footerBgColor = PdfColor.fromInt(0xFF1E3A8A);

    final members = period.members;
    final items = period.items;

    // Headers in RTL order: البند, التكلفة, [Members...]
    final headers = ['البند', 'التكلفة', ...members.map((m) => m.name)];

    // Data rows
    final tableRows = <List<String>>[];
    for (final item in items) {
      final row = <String>[
        item.title,
        EzbaFormatters.formatCurrency(item.totalCost, period.currency),
        ...members.map(
          (m) => EzbaFormatters.formatCurrency(
            item.getShareForMember(m.id, members),
            period.currency,
          ),
        ),
      ];
      tableRows.add(row);
    }

    // Totals row
    final totalRow = <String>[
      'الإجمالي',
      EzbaFormatters.formatCurrency(period.totalExpenses, period.currency),
      ...members.map(
        (m) => EzbaFormatters.formatCurrency(
          period.getMemberTotalShare(m.id),
          period.currency,
        ),
      ),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'كشف حساب مصاريف العزبة',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: headerBgColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      period.title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'التاريخ: ${EzbaFormatters.formatDate(period.createdAt)}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: alternateRowColor,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Text(
                        'إجمالي المصاريف: ${EzbaFormatters.formatCurrency(period.totalExpenses, period.currency)}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: headerBgColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.8),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: headerBgColor),
                  children: headers.map((header) {
                    return pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      child: pw.Text(
                        header,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Rows
                ...tableRows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final isEven = idx % 2 == 0;
                  final bgColor = isEven ? PdfColors.white : alternateRowColor;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bgColor),
                    children: row.asMap().entries.map((cellEntry) {
                      final cellIdx = cellEntry.key;
                      final cellValue = cellEntry.value;
                      final isItemName = cellIdx == 0;
                      final isTotalCost = cellIdx == 1;

                      return pw.Container(
                        alignment: isItemName
                            ? pw.Alignment.centerRight
                            : pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: pw.Text(
                          cellValue,
                          textAlign: isItemName
                              ? pw.TextAlign.right
                              : pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: (isItemName || isTotalCost)
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                            color: PdfColors.grey900,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
                // Total Summary Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: footerBgColor),
                  children: totalRow.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final value = entry.value;

                    return pw.Container(
                      alignment: idx == 0
                          ? pw.Alignment.centerRight
                          : pw.Alignment.center,
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      child: pw.Text(
                        value,
                        textAlign: idx == 0
                            ? pw.TextAlign.right
                            : pw.TextAlign.center,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          // Settlements / Summary block if any payments are logged
          _buildSummarySection(period, theme),
        ],
        footer: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'تم إنشاء هذا التقرير عبر تطبيق العزبة • صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummarySection(EzbaPeriod period, pw.ThemeData theme) {
    final settlements = period.calculateSettlements();
    final detailed = period.calculateDetailedSettlements();

    const sectionBg = PdfColor.fromInt(0xFFF8FAFC);
    const borderCol = PdfColor.fromInt(0xFFE2E8F0);
    const headerBlue = PdfColor.fromInt(0xFF2B78E4);
    const darkBg = PdfColor.fromInt(0xFF1E3A8A);
    const orangeBg = PdfColor.fromInt(0xFFFFF7ED);
    const greenBg = PdfColor.fromInt(0xFFDCFCE7);

    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ═══════════════════════════════════════════════════
          // قسم 1 — ملخص حصص الأعضاء (النصيب / المدفوع / الصافي)
          // ═══════════════════════════════════════════════════
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: sectionBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: borderCol, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ملخص الحسابات ومستحقات الأعضاء',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 8),
                ...period.members.map((m) {
                  final net = period.getMemberNetBalance(m.id);
                  final share = period.getMemberTotalShare(m.id);
                  final paid = period.getMemberTotalPaid(m.id);

                  String statusText;
                  PdfColor statusColor;
                  if (net.abs() < 0.01) {
                    statusText = 'خالص ✓';
                    statusColor = PdfColors.grey700;
                  } else if (net > 0) {
                    statusText =
                        'له: +${EzbaFormatters.formatCurrency(net, period.currency)}';
                    statusColor = PdfColors.green700;
                  } else {
                    statusText =
                        'عليه: ${EzbaFormatters.formatCurrency(net.abs(), period.currency)}';
                    statusColor = PdfColors.red700;
                  }

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${m.name}:  النصيب: ${EzbaFormatters.formatAmount(share)}  |  دفع: ${EzbaFormatters.formatAmount(paid)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          statusText,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          if (detailed.isNotEmpty) ...[
            pw.SizedBox(height: 14),

            // ═══════════════════════════════════════════════════
            // قسم 2 — خلاصة ما سيدفعه كل طرف ولمن (مفصّل بالبنود)
            // ═══════════════════════════════════════════════════
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: sectionBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderCol, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // عنوان القسم
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: headerBlue,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Text(
                      'خلاصة ما سيدفعه كل طرف ولمن',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // بطاقة لكل عضو
                  ...detailed.map((s) {
                    final isZero = s.totalToPay < 0.01;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderCol, width: 0.8),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            // رأس بطاقة العضو
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: isZero ? greenBg : orangeBg,
                                borderRadius: const pw.BorderRadius.only(
                                  topLeft: pw.Radius.circular(6),
                                  topRight: pw.Radius.circular(6),
                                ),
                              ),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    '> طرف أهل ${s.memberName}',
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: isZero
                                          ? PdfColors.green800
                                          : const PdfColor.fromInt(0xFFEA580C),
                                    ),
                                  ),
                                  pw.Text(
                                    isZero
                                        ? 'لا يوجد عليه شيء'
                                        : EzbaFormatters.formatCurrency(
                                            s.totalToPay,
                                            period.currency,
                                          ),
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: isZero
                                          ? PdfColors.green800
                                          : PdfColors.red800,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // بنود التفصيل
                            if (!isZero)
                              pw.Padding(
                                padding: const pw.EdgeInsets.fromLTRB(
                                  12,
                                  6,
                                  12,
                                  8,
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: s.breakdowns.asMap().entries.map((
                                    entry,
                                  ) {
                                    final idx = entry.key;
                                    final b = entry.value;
                                    return pw.Padding(
                                      padding: const pw.EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: pw.Row(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text(
                                            '${idx + 1}. ${b.itemTitle}  ( لـ ${b.toMemberName} )',
                                            style: const pw.TextStyle(
                                              fontSize: 9,
                                            ),
                                          ),
                                          pw.Text(
                                            EzbaFormatters.formatCurrency(
                                              b.amount,
                                              period.currency,
                                            ),
                                            style: pw.TextStyle(
                                              fontSize: 9,
                                              fontWeight: pw.FontWeight.bold,
                                              color: headerBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
