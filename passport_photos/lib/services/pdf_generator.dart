import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/photo_option.dart';

class PdfGenerator {
  static Future<Uint8List> generatePdf(File imageFile, PhotoOption option) async {
    final pdf = pw.Document();
    final imageData = await imageFile.readAsBytes();
    final pwImage = pw.MemoryImage(imageData);

    // Define actual sizes in millimeters
    const passportWidthMM = 35;
    const passportHeightMM = 45;
    const stampWidthMM = 20;
    const stampHeightMM = 25;

    // Convert millimeters to PDF points
    PdfPoint mmToPoint(double widthMM, double heightMM) {
      return PdfPoint(
        widthMM * PdfPageFormat.mm,
        heightMM * PdfPageFormat.mm,
      );
    }

    // Prepare images list
    List<pw.Widget> imageWidgets = [];

    if (option.type == PhotoType.passport) {
      PdfPoint size = mmToPoint(passportWidthMM.toDouble(), passportHeightMM.toDouble());
      imageWidgets.addAll(_generateRows(pwImage, size, option.numberOfPhotos, 4)); // 4 per row for passport
    } else if (option.type == PhotoType.stamp) {
      PdfPoint size = mmToPoint(stampWidthMM.toDouble(), stampHeightMM.toDouble());
      // For stamp photos, no 4-per-row logic is applied
      for (int i = 0; i < option.numberOfPhotos; i++) {
        imageWidgets.add(_buildImage(pwImage, size)); // Just add each photo without row logic
      }
    } else if (option.type == PhotoType.custom) {
      // For custom type, we need to handle both passport and stamp photos
      // The width and height fields are repurposed to store the count of each type in the UI

      // Generate passport photos first
      int passportCount = option.width?.toInt() ?? 0;
      PdfPoint passportSize = mmToPoint(passportWidthMM.toDouble(), passportHeightMM.toDouble());
      imageWidgets.addAll(_generateRows(pwImage, passportSize, passportCount, 4)); // 4 per row for passport

      // Then generate stamp photos
      int stampCount = option.height?.toInt() ?? 0;
      PdfPoint stampSize = mmToPoint(stampWidthMM.toDouble(), stampHeightMM.toDouble());
      // Just add each stamp photo without row logic
      for (int i = 0; i < stampCount; i++) {
        imageWidgets.add(_buildImage(pwImage, stampSize));
      }
    }

    // Now generate pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(10),
        build: (context) {
          return [
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 20),  // Margin from the top
              child: pw.Center(
                child: pw.Wrap(
                  spacing: 30,  // Spacing between images
                  runSpacing: 15,  // Vertical spacing between rows of images
                  children: imageWidgets,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _generateRows(
      pw.MemoryImage image, PdfPoint size, int totalPhotos, int photosPerRow) {
    List<pw.Widget> images = [];

    for (int i = 0; i < totalPhotos; i++) {
      images.add(_buildImage(image, size));
    }

    return images;
  }


  static pw.Widget _buildImage(pw.MemoryImage image, PdfPoint size) {
    return pw.Container(
      width: size.x,
      height: size.y,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.black,  // Border color
          width: 3,                // Border thickness (you can adjust)
        ),
      ),
      child: pw.Image(image, fit: pw.BoxFit.cover),
    );
  }

}
