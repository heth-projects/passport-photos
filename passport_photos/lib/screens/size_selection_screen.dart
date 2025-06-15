import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_option.dart';

class SizeSelectionScreen extends StatefulWidget {
  @override
  _SizeSelectionScreenState createState() => _SizeSelectionScreenState();
}

class _SizeSelectionScreenState extends State<SizeSelectionScreen> {
  PhotoType _selectedType = PhotoType.passport; // default

  // Number of photos (for all options):
  int _passportPhotoCount = 20; // default 20
  int _stampPhotoCount = 20;    // default 20

  // Initialize controllers immediately without using late
  final TextEditingController _passportController = TextEditingController(text: '20');
  final TextEditingController _stampController = TextEditingController(text: '20');

  @override
  void dispose() {
    // Dispose controllers when widget is disposed
    _passportController.dispose();
    _stampController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final File image = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Photo Size',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(0xFFE8E8F5),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Option Cards
                _buildOptionCard(
                  title: 'Passport Photos',
                  description: 'Standard passport photo dimensions',
                  type: PhotoType.passport,
                  child: _selectedType == PhotoType.passport
                      ? _buildCountTextField(
                    'Number of Passport Photos',
                    'Enter number of photos',
                    _passportController,
                        (value) {
                      setState(() {
                        _passportPhotoCount = int.tryParse(value) ?? 0;
                      });
                    },
                  )
                      : SizedBox(),
                ),

                SizedBox(height: 16),

                _buildOptionCard(
                  title: 'Stamp Photos',
                  description: 'Small format for official documents',
                  type: PhotoType.stamp,
                  child: _selectedType == PhotoType.stamp
                      ? _buildCountTextField(
                    'Number of Stamp Photos',
                    'Enter number of photos',
                    _stampController,
                        (value) {
                      setState(() {
                        _stampPhotoCount = int.tryParse(value) ?? 0;
                      });
                    },
                  )
                      : SizedBox(),
                ),

                SizedBox(height: 16),

                _buildOptionCard(
                  title: 'Custom Photos',
                  description: 'Specify count of photos',
                  type: PhotoType.custom,
                  child: _selectedType == PhotoType.custom
                      ? Column(
                    children: [
                      _buildCountTextField(
                        'Number of Passport Photos',
                        'Enter number of photos',
                        _passportController,
                            (value) {
                          setState(() {
                            _passportPhotoCount = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      _buildCountTextField(
                        'Number of Stamp Photos',
                        'Enter number of photos',
                        _stampController,
                            (value) {
                          setState(() {
                            _stampPhotoCount = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ],
                  )
                      : SizedBox(),
                ),

                SizedBox(height: 30),

                // Generate PDF Button
                GestureDetector(
                  onTap: () {
                    PhotoOption selectedOption;

                    if (_selectedType == PhotoType.custom) {
                      selectedOption = PhotoOption.custom(
                        width: _passportPhotoCount.toDouble(),
                        height: _stampPhotoCount.toDouble(),
                        numberOfPhotos: _passportPhotoCount + _stampPhotoCount,
                      );
                    } else if (_selectedType == PhotoType.passport) {
                      selectedOption = PhotoOption.passport(
                        numberOfPhotos: _passportPhotoCount,
                      );
                    } else {
                      selectedOption = PhotoOption.stamp(
                        numberOfPhotos: _stampPhotoCount,
                      );
                    }

                    Navigator.pushNamed(context, '/previewPdf', arguments: {
                      'image': image,
                      'option': selectedOption,
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Generate PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required PhotoType type,
    required Widget child,
  }) {
    bool isSelected = _selectedType == type;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Option Header
          InkWell(
            onTap: () {
              setState(() {
                _selectedType = type;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Custom Radio Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.deepPurple : Colors.white,
                        border: Border.all(
                          color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : null,
                    ),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Option Content
          AnimatedCrossFade(
            firstChild: SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: child,
            ),
            crossFadeState: isSelected
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildCountTextField(
      String label,
      String hint,
      TextEditingController controller,
      Function(String) onChanged,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          labelStyle: TextStyle(color: Colors.deepPurple.shade700, fontSize: 14),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.edit,
            color: Colors.deepPurple.shade400,
            size: 20,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}