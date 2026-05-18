import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/utils/formatters.dart';
import 'report_model.dart';

class ReportExporter {
  ReportExporter._();

  static Future<Uint8List> buildPdf({
    required ReportData data,
    required String currency,
    required String periodLabel,
    required String userName,
  }) async {
    final df = DateFormat('MMM d, y');
    // Load a Unicode-friendly font so currency symbols like ₨ render correctly.
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();
    final doc = pw.Document(
      title: 'Expense Report',
      theme: pw.ThemeData.withFont(base: regular, bold: bold, italic: italic),
    );

    final headerColor = PdfColor.fromInt(0xFF6C5CE7);
    final accentColor = PdfColor.fromInt(0xFF00B894);

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(28, 36, 28, 36),
        build: (context) => [
          // Title block
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(colors: [headerColor, accentColor]),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Expense Report',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('$userName · $periodLabel',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    _kpiBox('Total spent',
                        Money.format(data.totals.total, code: currency)),
                    pw.SizedBox(width: 10),
                    _kpiBox('Transactions', '${data.totals.count}'),
                    pw.SizedBox(width: 10),
                    _kpiBox('Paid by you',
                        Money.format(data.totals.paid, code: currency)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // By category
          pw.Text('By category',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            border: pw.TableBorder.symmetric(
                inside: const pw.BorderSide(color: PdfColors.grey300)),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: ['Category', 'Count', 'Amount', '% of total'],
            data: [
              for (final c in data.byCategory)
                [
                  c.category,
                  c.count.toString(),
                  Money.format(c.amount, code: currency),
                  data.totals.total <= 0
                      ? '0%'
                      : '${(c.amount / data.totals.total * 100).toStringAsFixed(1)}%',
                ],
            ],
          ),
          pw.SizedBox(height: 18),

          // Expenses
          pw.Text('Transactions',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            border: pw.TableBorder.symmetric(
                inside: const pw.BorderSide(color: PdfColors.grey300)),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerRight,
            },
            headers: ['Date', 'Description', 'Group', 'Category', 'Paid by', 'Amount'],
            data: [
              for (final e in data.items)
                [
                  df.format(e.spentAt),
                  e.description,
                  e.groupName,
                  e.category,
                  e.paidBy,
                  Money.format(e.amount, code: e.currency),
                ],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text('Generated by Expense · ${df.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _kpiBox(String label, String value) {
    const labelColor = PdfColor.fromInt(0xFF6B6B7A);
    const valueColor = PdfColor.fromInt(0xFF1A1A2E);
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                color: labelColor,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> savePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
