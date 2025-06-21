import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../services/pdf_generator.dart';
import '../models/photo_option.dart';

class PdfPreviewScreen extends StatefulWidget {
  @override
  _PdfPreviewScreenState createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Uint8List? _pdfData;
  bool _isLoading = false;
  String _fileName = "photos.pdf";
  int _totalPhotos = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final List<File> images = args['images'] as List<File>;
    final PhotoType photoType = args['photoType'] as PhotoType;
    final List<int> individualCounts = args['individualCounts'] as List<int>;
    final List<Map<String, dynamic>>? customDimensions = args['customDimensions'] as List<Map<String, dynamic>>?;

    // Calculate total photos
    _totalPhotos = individualCounts.fold(0, (sum, count) => sum + count);

    // Generate filename based on photo type
    String photoTypeString = photoType == PhotoType.passport
        ? 'passport'
        : photoType == PhotoType.stamp
        ? 'stamp'
        : 'custom';
    _fileName = "${photoTypeString}_photos_${DateTime.now().millisecondsSinceEpoch}.pdf";

    _generatePdf(images, photoType, individualCounts, customDimensions);
  }

  Future<void> _generatePdf(List<File> images, PhotoType photoType, List<int> individualCounts, List<Map<String, dynamic>>? customDimensions) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a single PhotoOption based on the photo type
      PhotoOption photoOption;

      switch (photoType) {
        case PhotoType.passport:
          photoOption = PhotoOption.passport(numberOfPhotos: _totalPhotos);
          break;
        case PhotoType.stamp:
          photoOption = PhotoOption.stamp(numberOfPhotos: _totalPhotos);
          break;
        case PhotoType.custom:
        // Use default custom dimensions if not provided
          photoOption = PhotoOption.custom(
            width: 3.5,
            height: 4.5,
            numberOfPhotos: _totalPhotos,
          );
          break;
      }

      // Generate PDF with the correct parameters
      final pdfData = await PdfGenerator.generatePdf(
          images,
          photoOption,
          individualCounts,
          customDimensions: customDimensions
      );

      setState(() {
        _pdfData = pdfData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfData != null) {
      try {
        final tempDir = await Directory.systemTemp.createTemp('pdf_share_');
        final file = File('${tempDir.path}/$_fileName');
        await file.writeAsBytes(_pdfData!);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Here are your generated photos',
          subject: 'Photo PDF - $_totalPhotos photos',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'PDF Preview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _pdfData != null
          ? _buildPreviewState()
          : _buildErrorState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: Colors.deepPurple,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Creating your PDF...',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Processing $_totalPhotos photos',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState() {
    return Column(
      children: [
        // Success banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF Ready!',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$_totalPhotos photos generated successfully',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // PDF Preview
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: PdfPreview(
              build: (format) => _pdfData!,
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: false,
              allowSharing: false,
              canDebug: false,
              previewPageMargin: EdgeInsets.all(0),
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: 3.0,
                ),
              ),
            ),
          ),
        ),

        // Bottom Actions
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Share Button
              GestureDetector(
                onTap: _sharePdf,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Share PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Done Button
              GestureDetector(
                onTap: _navigateToHome,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We couldn\'t generate your PDF. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}