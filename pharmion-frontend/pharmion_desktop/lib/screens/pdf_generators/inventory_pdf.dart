import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/inventory_service.dart';

class InventoryPdfGenerator {
  static Future<Uint8List> generate({
    required List<InventoryItemModel> items,
    required String pharmacyName,
    required String filterLabel,
    required bool showPharmacyColumn,
  }) async {
    final pdf = pw.Document();

    final ttf = await PdfGoogleFonts.nunitoRegular();
    final ttfBold = await PdfGoogleFonts.nunitoBold();

    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/pharmion_logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final totalItems = items.length;
    final lowStock = items.where((i) => i.isLowStock).length;
    final expiringSoon = items.where((i) => i.isExpiringSoon).length;
    final expired = items.where((i) => i.isExpired).length;

    const teal = PdfColor.fromInt(0xFF03989E);
    const tealLight = PdfColor.fromInt(0xFFE0F7F4);
    const headerBg = PdfColor.fromInt(0xFF1A3C47);
    const textDark = PdfColor.fromInt(0xFF1E293B);
    const textMid = PdfColor.fromInt(0xFF64748B);
    const rowAlt = PdfColor.fromInt(0xFFF8FAFC);
    const borderCol = PdfColor.fromInt(0xFFE2E8F0);
    const red = PdfColor.fromInt(0xFFDC2626);
    const redLight = PdfColor.fromInt(0xFFFEE2E2);
    const orange = PdfColor.fromInt(0xFFD97706);
    const orangeLight = PdfColor.fromInt(0xFFFEF3C7);
    const green = PdfColor.fromInt(0xFF059669);
    const greenLight = PdfColor.fromInt(0xFFD1FAE5);

    pw.TextStyle ts({double size = 8, PdfColor color = textDark, bool bold = false}) =>
        pw.TextStyle(font: bold ? ttfBold : ttf, fontSize: size, color: color);

    // ── Header ────────────────────────────────────────────────────────────
    pw.Widget buildHeader() => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const pw.BoxDecoration(color: headerBg),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(children: [
                if (logo != null) ...[
                  pw.Image(logo, width: 26, height: 26),
                  pw.SizedBox(width: 10),
                ],
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('PHARMION', style: ts(size: 14, color: PdfColors.white, bold: true)),
                  pw.Text('Inventory Status Report',
                      style: ts(size: 8, color: const PdfColor.fromInt(0xFFB0C4CE))),
                ]),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Generated: $dateStr',
                    style: ts(size: 7, color: const PdfColor.fromInt(0xFFB0C4CE))),
                pw.SizedBox(height: 3),
                pw.Text(pharmacyName, style: ts(size: 9, color: PdfColors.white, bold: true)),
                if (filterLabel.isNotEmpty)
                  pw.Text('Filter: $filterLabel',
                      style: ts(size: 7, color: const PdfColor.fromInt(0xFFB0C4CE))),
              ]),
            ],
          ),
        );

    // ── Summary cards ─────────────────────────────────────────────────────
    pw.Widget buildCard(String val, String label, PdfColor fg, PdfColor bg) =>
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                color: bg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderCol)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(val, style: ts(size: 16, color: fg, bold: true)),
              pw.SizedBox(height: 2),
              pw.Text(label, style: ts(size: 7, color: textMid)),
            ]),
          ),
        );

    pw.Widget buildSummary() => pw.Row(children: [
          buildCard('$totalItems', 'Total Items', teal, tealLight),
          pw.SizedBox(width: 8),
          buildCard('$lowStock', 'Low Stock', red, redLight),
          pw.SizedBox(width: 8),
          buildCard('$expiringSoon', 'Expiring Soon', orange, orangeLight),
          pw.SizedBox(width: 8),
          buildCard('$expired', 'Expired', red, redLight),
        ]);

    // ── Fixed column widths ───────────────────────────────────────────────
    const double wHand    = 44.0;
    const double wRes     = 44.0;
    const double wAvail   = 50.0;
    const double wReorder = 52.0;
    const double wExp     = 60.0;
    const double wStatus  = 54.0;

    // ── Table header ──────────────────────────────────────────────────────
    pw.Widget buildTableHeader() => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: const pw.BoxDecoration(color: teal),
          child: pw.Row(children: [
            if (showPharmacyColumn) ...[
              pw.Expanded(flex: 3, child: pw.Text('Product',  style: ts(size: 7, color: PdfColors.white, bold: true))),
              pw.Expanded(flex: 2, child: pw.Text('Pharmacy', style: ts(size: 7, color: PdfColors.white, bold: true))),
            ] else
              pw.Expanded(flex: 4, child: pw.Text('Product', style: ts(size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(width: wHand,    child: pw.Text('On Hand',    textAlign: pw.TextAlign.center, style: ts(size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(width: wRes,     child: pw.Text('Reserved',   textAlign: pw.TextAlign.center, style: ts(size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(width: wAvail,   child: pw.Text('Available',  textAlign: pw.TextAlign.center, style: ts(size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(width: wReorder, child: pw.Text('Reorder At', textAlign: pw.TextAlign.center, style: ts(size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(width: wExp,     child: pw.Text('Expiration', textAlign: pw.TextAlign.center, style: ts(size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(width: wStatus,  child: pw.Text('Status',     textAlign: pw.TextAlign.center, style: ts(size: 7, color: PdfColors.white, bold: true))),
          ]),
        );

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    PdfColor sBg(InventoryItemModel item) {
      if (item.isExpired || item.isLowStock) return redLight;
      if (item.isExpiringSoon) return orangeLight;
      return greenLight;
    }

    PdfColor sFg(InventoryItemModel item) {
      if (item.isExpired || item.isLowStock) return red;
      if (item.isExpiringSoon) return orange;
      return green;
    }

    String sLabel(InventoryItemModel item) {
      if (item.isExpired) return 'Expired';
      if (item.isLowStock) return 'Low Stock';
      if (item.isExpiringSoon) return 'Exp. Soon';
      return 'OK';
    }

    // ── Table rows ────────────────────────────────────────────────────────
    final rows = items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
          color: i.isEven ? PdfColors.white : rowAlt,
          border: const pw.Border(
              bottom: pw.BorderSide(color: borderCol, width: 0.5)),
        ),
        child: pw.Row(children: [
          if (showPharmacyColumn) ...[
            pw.Expanded(
              flex: 3,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(item.productName, style: ts(size: 7, bold: true)),
                if (item.productSku != null)
                  pw.Text(item.productSku!, style: ts(size: 6, color: textMid)),
              ]),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(item.pharmacyName, style: ts(size: 7, color: textMid)),
            ),
          ] else
            pw.Expanded(
              flex: 4,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(item.productName, style: ts(size: 8, bold: true)),
                if (item.productSku != null)
                  pw.Text(item.productSku!, style: ts(size: 6, color: textMid)),
              ]),
            ),
          pw.SizedBox(width: wHand,    child: pw.Text('${item.quantityOnHand}',    textAlign: pw.TextAlign.center, style: ts(size: 8, bold: true))),
          pw.SizedBox(width: wRes,     child: pw.Text('${item.reservedQuantity}',  textAlign: pw.TextAlign.center, style: ts(size: 8, color: textMid))),
          pw.SizedBox(width: wAvail,   child: pw.Text('${item.availableQuantity}', textAlign: pw.TextAlign.center, style: ts(size: 8, bold: true, color: item.isLowStock ? red : green))),
          pw.SizedBox(width: wReorder, child: pw.Text('${item.reorderLevel}',      textAlign: pw.TextAlign.center, style: ts(size: 8, color: textMid))),
          pw.SizedBox(width: wExp,     child: pw.Text(fmtDate(item.expirationDate),textAlign: pw.TextAlign.center, style: ts(size: 7, color: item.isExpired || item.isExpiringSoon ? orange : textMid))),
          pw.SizedBox(
            width: wStatus,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: pw.BoxDecoration(
                  color: sBg(item),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Text(sLabel(item),
                  textAlign: pw.TextAlign.center,
                  style: ts(size: 6, bold: true, color: sFg(item))),
            ),
          ),
        ]),
      );
    }).toList();

    // ── Page ──────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (_) => buildHeader(),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          color: rowAlt,
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Pharmion — Inventory Status Report', style: ts(size: 7, color: textMid)),
                pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: ts(size: 7, color: textMid)),
              ]),
        ),
        build: (_) => [
          pw.SizedBox(height: 14),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              buildSummary(),
              pw.SizedBox(height: 14),
              buildTableHeader(),
              ...rows,
              if (items.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Center(
                      child: pw.Text('No items found.',
                          style: ts(size: 10, color: textMid))),
                ),
            ]),
          ),
          pw.SizedBox(height: 14),
        ],
      ),
    );

    return pdf.save();
  }
}