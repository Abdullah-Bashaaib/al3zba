import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/ezba_provider.dart';
import '../services/pdf_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final period = provider.activePeriod;

    return Scaffold(
      appBar: AppBar(
        title: Text('معاينة وتصدير PDF - ${period.title}'),
        centerTitle: false,
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateEzbaPdf(period),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'كشف_حساب_${period.title.replaceAll(' ', '_')}.pdf',
      ),
    );
  }
}
