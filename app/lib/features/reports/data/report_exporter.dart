import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

import 'report_model.dart';

class ReportExporter {
  ReportExporter._();

  // Returns a PDF-safe currency symbol for the given ISO code.
  // Only characters confirmed present in NotoSans Regular are used as symbols;
  // problematic glyphs like ₨ (U+20A8) and ₹ (U+20B9) are not in the font
  // and render as empty boxes, so we substitute readable ASCII equivalents.
  static String _pdfSymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return r'$ ';
      case 'EUR': return '\u20AC ';  // € – present in NotoSans
      case 'GBP': return '\u00A3 ';  // £ – Latin-1, always present
      case 'JPY': return '\u00A5 ';  // ¥ – Latin-1, always present
      case 'CAD': return r'C$ ';
      case 'AUD': return r'A$ ';
      case 'PKR': return 'Rs. ';     // ₨ NOT in NotoSans – use Rs.
      case 'INR': return 'Rs. ';     // ₹ NOT in NotoSans – use Rs.
      default:    return '${code.toUpperCase()} ';
    }
  }

  static Future<Uint8List> buildPdf({
    required ReportData data,
    required String currency,
    required String periodLabel,
    required String userName,
  }) async {
    final df = DateFormat('MMM d, y');
    // Load NotoSans for good Unicode coverage (€, £, ¥ etc. all present).
    // Falls back to Helvetica if offline — fmt() always uses PDF-safe symbols
    // so the output looks correct either way.
    pw.Font regular, bold, italic;
    try {
      regular = await PdfGoogleFonts.notoSansRegular();
      bold = await PdfGoogleFonts.notoSansBold();
      italic = await PdfGoogleFonts.notoSansItalic();
    } catch (_) {
      regular = pw.Font.helvetica();
      bold = pw.Font.helveticaBold();
      italic = pw.Font.helveticaOblique();
    }

    // Use attractive PDF-safe symbols (see _pdfSymbol above).
    String fmt(num amount, {String? code}) {
      final symbol = _pdfSymbol(code ?? currency);
      return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
    }
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
                        fmt(data.totals.total)),
                    pw.SizedBox(width: 10),
                    _kpiBox('Transactions', '${data.totals.count}'),
                    pw.SizedBox(width: 10),
                    _kpiBox('Paid by you',
                        fmt(data.totals.paid)),
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
                  fmt(c.amount),
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
                  fmt(e.amount, code: e.currency),
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
