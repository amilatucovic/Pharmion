import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/reservation_service.dart';

class ReservationsPdfGenerator {
  static Future<Uint8List> generate({
    required List<ReservationModel> reservations,
    required String pharmacyName,
    required String periodLabel,
    required String statusLabel,
  }) async {
    final pdf = pw.Document();

    // ── Fonts s Unicode podrškom ──────────────────────────────────────────
    final ttf = await PdfGoogleFonts.nunitoRegular();
    final ttfBold = await PdfGoogleFonts.nunitoBold();

    // ── Logo ──────────────────────────────────────────────────────────────
    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/pharmion_logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // ── Stats ─────────────────────────────────────────────────────────────
    final totalReservations = reservations.length;
    final totalRevenue =
        reservations.fold<double>(0, (s, r) => s + r.totalAmount);
    final totalPatientPays =
        reservations.fold<double>(0, (s, r) => s + r.patientPaysAmount);
    final totalInsurance =
        reservations.fold<double>(0, (s, r) => s + r.insurancePaysAmount);

    final statusCounts = <String, int>{};
    for (final r in reservations) {
      final s = r.reservationStateDisplay;
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
    }

    // ── Colours ───────────────────────────────────────────────────────────
    const teal = PdfColor.fromInt(0xFF03989E);
    const tealLight = PdfColor.fromInt(0xFFE0F7F4);
    const headerBg = PdfColor.fromInt(0xFF1A3C47);
    const textDark = PdfColor.fromInt(0xFF1E293B);
    const textMid = PdfColor.fromInt(0xFF64748B);
    const rowAlt = PdfColor.fromInt(0xFFF8FAFC);
    const borderCol = PdfColor.fromInt(0xFFE2E8F0);
    const green = PdfColor.fromInt(0xFF059669);
    const greenLight = PdfColor.fromInt(0xFFD1FAE5);
    const orange = PdfColor.fromInt(0xFFD97706);
    const orangeLight = PdfColor.fromInt(0xFFFEF3C7);
    const red = PdfColor.fromInt(0xFFDC2626);
    const redLight = PdfColor.fromInt(0xFFFEE2E2);
    const blue = PdfColor.fromInt(0xFF2563EB);
    const blueLight = PdfColor.fromInt(0xFFDBEAFE);

    pw.TextStyle _style(
            {double size = 8,
            PdfColor color = textDark,
            bool bold = false}) =>
        pw.TextStyle(
            font: bold ? ttfBold : ttf, fontSize: size, color: color);

    // ── Header ────────────────────────────────────────────────────────────
    pw.Widget _header() => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const pw.BoxDecoration(color: headerBg),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(children: [
                if (logo != null) ...[
                  pw.Image(logo, width: 28, height: 28),
                  pw.SizedBox(width: 10),
                ],
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PHARMION',
                          style: _style(
                              size: 15,
                              color: PdfColors.white,
                              bold: true)),
                      pw.Text('Reservations Report',
                          style: _style(
                              size: 8,
                              color: const PdfColor.fromInt(0xFFB0C4CE))),
                    ]),
              ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated: $dateStr',
                        style: _style(
                            size: 7,
                            color: const PdfColor.fromInt(0xFFB0C4CE))),
                    pw.SizedBox(height: 3),
                    pw.Text(pharmacyName,
                        style: _style(
                            size: 9,
                            color: PdfColors.white,
                            bold: true)),
                    if (periodLabel.isNotEmpty)
                      pw.Text('Period: $periodLabel',
                          style: _style(
                              size: 7,
                              color: const PdfColor.fromInt(0xFFB0C4CE))),
                    if (statusLabel.isNotEmpty)
                      pw.Text('Status: $statusLabel',
                          style: _style(
                              size: 7,
                              color: const PdfColor.fromInt(0xFFB0C4CE))),
                  ]),
            ],
          ),
        );

    // ── Summary cards ─────────────────────────────────────────────────────
    pw.Widget _finCard(
            String value, String label, PdfColor fg, PdfColor bg) =>
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                color: bg,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderCol)),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(value,
                      style: _style(size: 14, color: fg, bold: true)),
                  pw.SizedBox(height: 2),
                  pw.Text(label, style: _style(size: 7, color: textMid)),
                ]),
          ),
        );

    pw.Widget _summarySection() => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                _finCard('$totalReservations', 'Total Reservations',
                    teal, tealLight),
                pw.SizedBox(width: 8),
                _finCard('${totalRevenue.toStringAsFixed(2)} KM',
                    'Total Revenue', green, greenLight),
                pw.SizedBox(width: 8),
                _finCard('${totalPatientPays.toStringAsFixed(2)} KM',
                    'Patient Pays', blue, blueLight),
                pw.SizedBox(width: 8),
                _finCard('${totalInsurance.toStringAsFixed(2)} KM',
                    'Insurance Pays', orange, orangeLight),
              ]),
              if (statusCounts.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6)),
                      border: pw.Border.all(color: borderCol)),
                  child: pw.Wrap(spacing: 8, runSpacing: 4, children: [
                    pw.Text('By Status:',
                        style: _style(size: 7, color: textMid, bold: true)),
                    ...statusCounts.entries.map((e) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: pw.BoxDecoration(
                              color: rowAlt,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4)),
                              border:
                                  pw.Border.all(color: borderCol)),
                          child: pw.Text('${e.key}: ${e.value}',
                              style: _style(
                                  size: 7,
                                  color: textDark,
                                  bold: true)),
                        )),
                  ]),
                ),
              ],
            ]);

    // ── Table header ──────────────────────────────────────────────────────
    pw.Widget _tableHeader() => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: const pw.BoxDecoration(color: teal),
          child: pw.Row(children: [
            pw.SizedBox(
                width: 24,
                child: pw.Text('#',
                    style: _style(
                        size: 7, color: PdfColors.white, bold: true))),
            pw.Expanded(
                flex: 3,
                child: pw.Text('Patient',
                    style: _style(
                        size: 7, color: PdfColors.white, bold: true))),
            pw.Expanded(
                flex: 2,
                child: pw.Text('Pharmacy',
                    style: _style(
                        size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(
                width: 40,
                child: pw.Text('Items',
                    textAlign: pw.TextAlign.center,
                    style: _style(
                        size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(
                width: 70,
                child: pw.Text('Total',
                    textAlign: pw.TextAlign.right,
                    style: _style(
                        size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(
                width: 70,
                child: pw.Text('Patient Pays',
                    textAlign: pw.TextAlign.right,
                    style: _style(
                        size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(
                width: 62,
                child: pw.Text('Date',
                    textAlign: pw.TextAlign.center,
                    style: _style(
                        size: 7, color: PdfColors.white, bold: true))),
            pw.SizedBox(
                width: 70,
                child: pw.Text('Status',
                    textAlign: pw.TextAlign.center,
                    style: _style(
                        size: 7, color: PdfColors.white, bold: true))),
          ]),
        );

    String _fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    PdfColor _statusFg(String state) {
      switch (state.toLowerCase()) {
        case 'pickedup':
          return teal;
        case 'approved':
          return green;
        case 'readyforpickup':
          return blue;
        case 'submitted':
          return orange;
        case 'rejected':
        case 'cancelled':
          return red;
        default:
          return textMid;
      }
    }

    PdfColor _statusBg(String state) {
      switch (state.toLowerCase()) {
        case 'pickedup':
          return tealLight;
        case 'approved':
          return greenLight;
        case 'readyforpickup':
          return blueLight;
        case 'submitted':
          return orangeLight;
        case 'rejected':
        case 'cancelled':
          return redLight;
        default:
          return rowAlt;
      }
    }

    // ── Table rows ────────────────────────────────────────────────────────
    final tableRows = reservations.asMap().entries.map((entry) {
      final i = entry.key;
      final r = entry.value;
      final fg = _statusFg(r.reservationState);
      final bg = _statusBg(r.reservationState);
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
          color: i.isEven ? PdfColors.white : rowAlt,
          border: const pw.Border(
              bottom: pw.BorderSide(color: borderCol, width: 0.5)),
        ),
        child: pw.Row(children: [
          pw.SizedBox(
              width: 24,
              child: pw.Text('${i + 1}',
                  style: _style(size: 7, color: textMid))),
          pw.Expanded(
              flex: 3,
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(r.patientName,
                        style: _style(size: 8, bold: true)),
                    pw.Text(r.patientEmail,
                        style: _style(size: 6, color: textMid)),
                  ])),
          pw.Expanded(
              flex: 2,
              child: pw.Text(r.pharmacyName,
                  style: _style(size: 7, color: textMid))),
          pw.SizedBox(
              width: 40,
              child: pw.Text('${r.items.length}',
                  textAlign: pw.TextAlign.center,
                  style: _style(size: 8, color: textMid))),
          pw.SizedBox(
              width: 70,
              child: pw.Text(
                  '${r.totalAmount.toStringAsFixed(2)} KM',
                  textAlign: pw.TextAlign.right,
                  style: _style(size: 8, bold: true))),
          pw.SizedBox(
              width: 70,
              child: pw.Text(
                  '${r.patientPaysAmount.toStringAsFixed(2)} KM',
                  textAlign: pw.TextAlign.right,
                  style: _style(size: 8, color: textMid))),
          pw.SizedBox(
              width: 62,
              child: pw.Text(_fmtDate(r.createdAt),
                  textAlign: pw.TextAlign.center,
                  style: _style(size: 7, color: textMid))),
          pw.SizedBox(
              width: 70,
              child: pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: pw.BoxDecoration(
                    color: bg,
                    borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4))),
                child: pw.Text(r.reservationStateDisplay,
                    textAlign: pw.TextAlign.center,
                    style: _style(size: 6, bold: true, color: fg)),
              )),
        ]),
      );
    }).toList();

    // ── Totals row ────────────────────────────────────────────────────────
    pw.Widget _totalsRow() => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: const pw.BoxDecoration(color: tealLight),
          child: pw.Row(children: [
            pw.SizedBox(width: 24),
            pw.Expanded(
                flex: 3,
                child: pw.Text('TOTAL',
                    style: _style(size: 8, bold: true))),
            pw.Expanded(flex: 2, child: pw.SizedBox()),
            pw.SizedBox(
                width: 40,
                child: pw.Text('$totalReservations',
                    textAlign: pw.TextAlign.center,
                    style: _style(size: 8, bold: true))),
            pw.SizedBox(
                width: 70,
                child: pw.Text(
                    '${totalRevenue.toStringAsFixed(2)} KM',
                    textAlign: pw.TextAlign.right,
                    style: _style(size: 8, bold: true, color: green))),
            pw.SizedBox(
                width: 70,
                child: pw.Text(
                    '${totalPatientPays.toStringAsFixed(2)} KM',
                    textAlign: pw.TextAlign.right,
                    style: _style(size: 8, bold: true, color: blue))),
            pw.SizedBox(width: 62),
            pw.SizedBox(width: 70),
          ]),
        );

    // ── Page ──────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        header: (_) => _header(),
        footer: (ctx) => pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          color: rowAlt,
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Pharmion — Reservations Report',
                    style: _style(size: 7, color: textMid)),
                pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: _style(size: 7, color: textMid)),
              ]),
        ),
        build: (_) => [
          pw.SizedBox(height: 14),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _summarySection(),
                  pw.SizedBox(height: 14),
                  _tableHeader(),
                  ...tableRows,
                  if (reservations.isNotEmpty) _totalsRow(),
                  if (reservations.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(20),
                      child: pw.Center(
                          child: pw.Text('No reservations found.',
                              style: _style(size: 10, color: textMid))),
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