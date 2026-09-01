import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/medical_record.dart';

/// Renders a [DigitalPrescription] into a PDF the patient can keep.
///
/// A digital prescription is rows on the server, not a stored file — there is
/// no document endpoint to fetch — so the download is produced here from the
/// same fields the detail screen shows. Nothing is invented: every line comes
/// off the prescription, and a field the server left empty is omitted rather
/// than filled with a placeholder.
class PrescriptionPdf {
  const PrescriptionPdf();

  /// `prescription-194BC2.pdf`.
  String fileName(DigitalPrescription prescription) =>
      'prescription-${prescription.reference}.pdf';

  Future<List<int>> build(
    DigitalPrescription prescription, {
    required String issuedOn,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _heading(prescription),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey400, height: 1),
            pw.SizedBox(height: 16),
            _field('Prescribed by', prescription.doctorName),
            if (prescription.specialty.isNotEmpty)
              _field('Specialty', prescription.specialty),
            _field('Issued', issuedOn),
            if (prescription.diagnosis.isNotEmpty)
              _field('Diagnosis', prescription.diagnosis),
            pw.SizedBox(height: 12),
            pw.Text(
              'Medications',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            for (final medication in prescription.medications) ...[
              _medication(medication),
              pw.SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );

    return document.save();
  }

  pw.Widget _heading(DigitalPrescription prescription) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Digital Prescription',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'ID: ${prescription.reference}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Text(
          prescription.state == PrescriptionState.active ? 'Active' : 'Expired',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _field(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _medication(Medication medication) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  medication.name,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                medication.durationLabel,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          _field('Dosage', medication.dosage),
          _field('Frequency', medication.frequency),
          // Notes are optional on the prescribing form; a bare "Instructions:"
          // reads as a line that failed to render.
          if (medication.instructions.isNotEmpty)
            _field('Instructions', medication.instructions),
        ],
      ),
    );
  }
}
