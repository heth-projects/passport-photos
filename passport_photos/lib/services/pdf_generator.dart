import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/photo_option.dart';

class PdfGenerator {
  static Future<Uint8List> generatePdf(
      List<File> imageFiles,
      PhotoOption option,
      List<int> individualCounts,
      {List<Map<String, dynamic>>? customDimensions}
      ) async {
    final pdf = pw.Document();

    // Define actual sizes in millimeters
    const passportWidthMM = 35;
    const passportHeightMM = 45;
    const stampWidthMM = 25;
    const stampHeightMM = 35;

    // Convert millimeters to PDF points
    PdfPoint mmToPoint(double widthMM, double heightMM) {
      return PdfPoint(
        widthMM * PdfPageFormat.mm,
        heightMM * PdfPageFormat.mm,
      );
    }

    // Prepare all image widgets with their dimensions
    List<Map<String, dynamic>> allImageData = [];

    // Process each image with its individual count
    for (int imageIndex = 0; imageIndex < imageFiles.length; imageIndex++) {
      final imageFile = imageFiles[imageIndex];
      final count = individualCounts[imageIndex];

      if (count <= 0) continue; // Skip if count is 0

      final imageData = await imageFile.readAsBytes();
      final pwImage = pw.MemoryImage(imageData);

      // Generate photos based on selected type
      if (option.type == PhotoType.passport) {
        PdfPoint size = mmToPoint(passportWidthMM.toDouble(), passportHeightMM.toDouble());
        for (int i = 0; i < count; i++) {
          allImageData.add({
            'image': pwImage,
            'size': size,
            'type': PhotoType.passport,
          });
        }
      } else if (option.type == PhotoType.stamp) {
        PdfPoint size = mmToPoint(stampWidthMM.toDouble(), stampHeightMM.toDouble());
        for (int i = 0; i < count; i++) {
          allImageData.add({
            'image': pwImage,
            'size': size,
            'type': PhotoType.stamp,
          });
        }
      } else if (option.type == PhotoType.custom) {
        // Use custom dimensions for this specific image
        if (customDimensions != null && imageIndex < customDimensions.length) {
          final customDim = customDimensions[imageIndex];
          double widthMM = customDim['widthInMM'] ?? passportWidthMM.toDouble();
          double heightMM = customDim['heightInMM'] ?? passportHeightMM.toDouble();
          PdfPoint size = mmToPoint(widthMM, heightMM);

          for (int i = 0; i < count; i++) {
            allImageData.add({
              'image': pwImage,
              'size': size,
              'type': PhotoType.custom,
              'widthMM': widthMM,
              'heightMM': heightMM,
            });
          }
        }
      }
    }

    if (allImageData.isEmpty) {
      throw Exception('No photos to generate');
    }

    // Generate PDF pages based on photo type
    if (option.type == PhotoType.custom) {
      _generateCustomPages(pdf, allImageData);
    } else {
      _generateStandardPages(pdf, allImageData, option.type);
    }

    return pdf.save();
  }

  static void _generateCustomPages(pw.Document pdf, List<Map<String, dynamic>> allImageData) {
    // A4 dimensions in points (minus margins)
    final double marginPoints = 15 * PdfPageFormat.mm;
    final double paddingPoints = 10 * PdfPageFormat.mm;
    final double availableWidth = PdfPageFormat.a4.width - (2 * marginPoints) - (2 * paddingPoints);
    final double availableHeight = PdfPageFormat.a4.height - (2 * marginPoints) - (2 * paddingPoints);

    // Minimum spacing between images
    final double minSpacing = 8 * PdfPageFormat.mm;

    List<Map<String, dynamic>> currentPageImages = [];
    int imageIndex = 0;

    while (imageIndex < allImageData.length) {
      currentPageImages.clear();

      // Try to fit as many images as possible on current page
      double currentY = 0;

      while (imageIndex < allImageData.length && currentY < availableHeight) {
        List<Map<String, dynamic>> currentRow = [];
        double currentX = 0;
        double rowHeight = 0;

        // Fill current row
        while (imageIndex < allImageData.length && currentX < availableWidth) {
          final imageData = allImageData[imageIndex];
          final size = imageData['size'] as PdfPoint;

          // Check if image fits in current row
          if (currentX + size.x <= availableWidth) {
            currentRow.add({
              'data': imageData,
              'x': currentX,
              'y': currentY,
            });
            currentX += size.x + minSpacing;
            rowHeight = math.max(rowHeight, size.y);
            imageIndex++;
          } else {
            break; // Move to next row
          }
        }

        // Check if row fits in current page
        if (currentY + rowHeight <= availableHeight && currentRow.isNotEmpty) {
          // Distribute images evenly across the row width
          if (currentRow.length > 1) {
            double totalImageWidth = currentRow.fold(0.0, (sum, item) {
              return sum + (item['data']['size'] as PdfPoint).x;
            });
            double totalSpacing = availableWidth - totalImageWidth;
            double spacingBetweenImages = totalSpacing / (currentRow.length - 1);

            // Recalculate X positions with even spacing
            double newX = 0;
            for (int i = 0; i < currentRow.length; i++) {
              currentRow[i]['x'] = newX;
              newX += (currentRow[i]['data']['size'] as PdfPoint).x + spacingBetweenImages;
            }
          }

          currentPageImages.addAll(currentRow);
          currentY += rowHeight + minSpacing;
        } else {
          // Reset index to retry these images on next page
          imageIndex -= currentRow.length;
          break;
        }
      }

      // Add page with current images
      if (currentPageImages.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(15),
            build: (context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Stack(
                  children: currentPageImages.map((item) {
                    return pw.Positioned(
                      left: item['x'],
                      top: item['y'],
                      child: _buildImage(
                        item['data']['image'] as pw.MemoryImage,
                        item['data']['size'] as PdfPoint,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      }
    }
  }

  static void _generateStandardPages(pw.Document pdf, List<Map<String, dynamic>> allImageData, PhotoType photoType) {
    // Calculate photos per page based on photo type
    int photosPerPage;
    int photosPerRow;

    if (photoType == PhotoType.passport) {
      photosPerRow = 4;
      photosPerPage = 20; // 4 photos per row × 5 rows = 20 photos per page
    } else if (photoType == PhotoType.stamp) {
      photosPerRow = 6;
      photosPerPage = 36; // 6 photos per row × 6 rows = 36 photos per page
    } else {
      photosPerRow = 4;
      photosPerPage = 24; // 4 photos per row × 6 rows = 24 photos per page
    }

    // Split photos into pages
    List<List<Map<String, dynamic>>> pages = [];
    for (int i = 0; i < allImageData.length; i += photosPerPage) {
      int end = (i + photosPerPage < allImageData.length)
          ? i + photosPerPage
          : allImageData.length;
      pages.add(allImageData.sublist(i, end));
    }

    // Generate PDF pages
    for (List<Map<String, dynamic>> pageImages in pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(15),
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Align(
                alignment: pw.Alignment.topLeft,
                child: _buildPhotoGrid(pageImages, photosPerRow, photoType),
              ),
            );
          },
        ),
      );
    }
  }

  static pw.Widget _buildPhotoGrid(List<Map<String, dynamic>> imageData, int photosPerRow, PhotoType photoType) {
    List<pw.Widget> rows = [];

    // Calculate spacing based on photo type
    double horizontalSpacing;
    double verticalSpacing;
    double photoWidth;

    if (photoType == PhotoType.passport) {
      horizontalSpacing = 12;
      verticalSpacing = 10;
      photoWidth = 35 * PdfPageFormat.mm;
    } else if (photoType == PhotoType.stamp) {
      horizontalSpacing = 8;
      verticalSpacing = 8;
      photoWidth = 25 * PdfPageFormat.mm;
    } else {
      horizontalSpacing = 10;
      verticalSpacing = 10;
      photoWidth = 35 * PdfPageFormat.mm;
    }

    // Calculate the total width of a full row
    double totalRowWidth = (photoWidth * photosPerRow) + (horizontalSpacing * (photosPerRow - 1));

    // Calculate available width
    double availableWidth = PdfPageFormat.a4.width - (15 * 2) - (10 * 2);

    // Calculate spacing to center the grid
    double leftPadding = math.max(0, (availableWidth - totalRowWidth) / 2);

    for (int i = 0; i < imageData.length; i += photosPerRow) {
      int end = (i + photosPerRow < imageData.length) ? i + photosPerRow : imageData.length;
      List<Map<String, dynamic>> rowImageData = imageData.sublist(i, end);

      // Create row widgets
      List<pw.Widget> rowChildren = [];
      for (int j = 0; j < rowImageData.length; j++) {
        final imgData = rowImageData[j];
        rowChildren.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(
              right: j < rowImageData.length - 1 ? horizontalSpacing : 0,
            ),
            child: _buildImage(
              imgData['image'] as pw.MemoryImage,
              imgData['size'] as PdfPoint,
            ),
          ),
        );
      }

      rows.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(left: leftPadding),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: rows.map((row) =>
          pw.Padding(
            padding: pw.EdgeInsets.only(
              bottom: verticalSpacing,
            ),
            child: row,
          )
      ).toList(),
    );
  }

  static pw.Widget _buildImage(pw.MemoryImage image, PdfPoint size) {
    return pw.Container(
      width: size.x,
      height: size.y,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.black,
          width: 1,
        ),
      ),
      child: pw.ClipRect(
        child: pw.Image(
          image,
          fit: pw.BoxFit.cover,
        ),
      ),
    );
  }
}