import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_option.dart';

enum DimensionUnit { cm, inch, feet }

class CustomDimensions {
  double width;
  double height;
  DimensionUnit unit;

  CustomDimensions({
    required this.width,
    required this.height,
    required this.unit,
  });
}

class SizeSelectionScreen extends StatefulWidget {
  @override
  _SizeSelectionScreenState createState() => _SizeSelectionScreenState();
}

class _SizeSelectionScreenState extends State<SizeSelectionScreen> {
  PhotoType _selectedType = PhotoType.passport; // default

  // Individual photo counts for each image
  List<int> _individualPhotoCounts = [];
  List<TextEditingController> _photoControllers = [];

  // Custom dimensions for each image
  List<CustomDimensions> _customDimensions = [];
  List<TextEditingController> _customWidthControllers = [];
  List<TextEditingController> _customHeightControllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize will be done in build method when we have access to images
  }

  void _initializeControllers(int imageCount) {
    if (_photoControllers.length != imageCount) {
      // Dispose existing controllers
      for (var controller in _photoControllers) {
        controller.dispose();
      }
      for (var controller in _customWidthControllers) {
        controller.dispose();
      }
      for (var controller in _customHeightControllers) {
        controller.dispose();
      }

      // Create new controllers and counts
      _photoControllers.clear();
      _individualPhotoCounts.clear();
      _customDimensions.clear();
      _customWidthControllers.clear();
      _customHeightControllers.clear();

      for (int i = 0; i < imageCount; i++) {
        _photoControllers.add(TextEditingController(text: '10'));
        _individualPhotoCounts.add(10);

        // Initialize custom dimensions for each image
        _customDimensions.add(CustomDimensions(
          width: 3.5,
          height: 4.5,
          unit: DimensionUnit.cm,
        ));
        _customWidthControllers.add(TextEditingController(text: '3.5'));
        _customHeightControllers.add(TextEditingController(text: '4.5'));
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers when widget is disposed
    for (var controller in _photoControllers) {
      controller.dispose();
    }
    for (var controller in _customWidthControllers) {
      controller.dispose();
    }
    for (var controller in _customHeightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePhotoCount(int index, String value) {
    setState(() {
      _individualPhotoCounts[index] = int.tryParse(value) ?? 0;
    });
  }

  void _updateCustomDimension(int index, {double? width, double? height, DimensionUnit? unit}) {
    setState(() {
      if (width != null) _customDimensions[index].width = width;
      if (height != null) _customDimensions[index].height = height;
      if (unit != null) _customDimensions[index].unit = unit;
    });
  }

  int get _totalPhotoCount {
    return _individualPhotoCounts.fold(0, (sum, count) => sum + count);
  }

  // Convert dimensions to millimeters for consistency
  double _convertToMM(double value, DimensionUnit unit) {
    switch (unit) {
      case DimensionUnit.cm:
        return value * 10;
      case DimensionUnit.inch:
        return value * 25.4;
      case DimensionUnit.feet:
        return value * 304.8;
    }
  }

  String _getUnitSymbol(DimensionUnit unit) {
    switch (unit) {
      case DimensionUnit.cm:
        return 'cm';
      case DimensionUnit.inch:
        return 'in';
      case DimensionUnit.feet:
        return 'ft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<File> images = ModalRoute.of(context)!.settings.arguments as List<File>;

    // Initialize controllers based on image count
    _initializeControllers(images.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Photo Size',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(0xFFE8E8F5),
        child: Column(
          children: [
            // Images Preview Section - Fixed height
            Container(
              height: 140,
              margin: EdgeInsets.all(16),
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library, color: Colors.deepPurple, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${images.length} image${images.length > 1 ? 's' : ''} selected',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Total: $_totalPhotoCount',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Images Grid - Fixed height with proper scrolling
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: images.length <= 4
                          ? Row(
                        children: images.asMap().entries.map((entry) {
                          return Expanded(
                            child: Container(
                              height: 70,
                              margin: EdgeInsets.only(
                                right: entry.key < images.length - 1 ? 8 : 0,
                                bottom: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  entry.value,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                          : GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                images[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Option Cards
                    _buildOptionCard(
                      title: 'Passport Photos',
                      description: 'Standard passport photo dimensions (3.5cm × 4.5cm)',
                      type: PhotoType.passport,
                      child: _selectedType == PhotoType.passport
                          ? _buildIndividualPhotoCountSection(images)
                          : SizedBox(),
                    ),

                    SizedBox(height: 16),

                    _buildOptionCard(
                      title: 'Stamp Photos',
                      description: 'Small format for official documents (2.5cm × 3.5cm)',
                      type: PhotoType.stamp,
                      child: _selectedType == PhotoType.stamp
                          ? _buildIndividualPhotoCountSection(images)
                          : SizedBox(),
                    ),

                    SizedBox(height: 16),

                    _buildOptionCard(
                      title: 'Custom Photos',
                      description: 'Specify custom dimensions and count for each photo',
                      type: PhotoType.custom,
                      child: _selectedType == PhotoType.custom
                          ? _buildCustomPhotoSection(images)
                          : SizedBox(),
                    ),

                    SizedBox(height: 100), // Extra space for floating button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Generate PDF Button
      floatingActionButton: Container(
        width: double.infinity,
        height: 56,
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_totalPhotoCount == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please set at least one photo count greater than 0'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            // Validate custom dimensions if custom type is selected
            if (_selectedType == PhotoType.custom) {
              for (int i = 0; i < _customDimensions.length; i++) {
                double? width = double.tryParse(_customWidthControllers[i].text);
                double? height = double.tryParse(_customHeightControllers[i].text);

                if (width == null || height == null || width <= 0 || height <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter valid dimensions for Photo ${i + 1}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }
            }

            // Navigate with appropriate data structure
            Navigator.pushNamed(context, '/previewPdf', arguments: {
              'images': images,
              'photoType': _selectedType,
              'individualCounts': _individualPhotoCounts,
              'customDimensions': _selectedType == PhotoType.custom ?
              _customDimensions.asMap().entries.map((entry) => {
                'index': entry.key,
                'width': entry.value.width,
                'height': entry.value.height,
                'unit': _getUnitSymbol(entry.value.unit),
                'widthInMM': _convertToMM(entry.value.width, entry.value.unit),
                'heightInMM': _convertToMM(entry.value.height, entry.value.unit),
              }).toList() : null,
            });
          },
          backgroundColor: _totalPhotoCount > 0 ? Colors.deepPurple : Colors.grey,
          elevation: 8,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Generate PDF ($_totalPhotoCount photos)',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Custom Radio Button
                  Container(
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
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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

  Widget _buildCustomPhotoSection(List<File> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with global actions
        Row(
          children: [
            Expanded(
              child: Text(
                'Set dimensions & count for each photo:',
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8),
            // Apply to all button
            _buildApplyToAllButton(),
          ],
        ),
        SizedBox(height: 12),

        // Quick set count buttons
        Row(
          children: [
            Text(
              'Quick set count:',
              style: TextStyle(
                color: Colors.deepPurple.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            _buildQuickSetButton('5', 5),
            SizedBox(width: 4),
            _buildQuickSetButton('10', 10),
            SizedBox(width: 4),
            _buildQuickSetButton('20', 20),
          ],
        ),
        SizedBox(height: 16),

        // Individual photo custom settings
        ...List.generate(images.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: _buildIndividualCustomPhotoCard(images[index], index),
          );
        }),

        // Enhanced Summary
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total photos to generate:',
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${images.length} photos selected',
                    style: TextStyle(
                      color: Colors.deepPurple.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_totalPhotoCount',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'photos',
                    style: TextStyle(
                      color: Colors.deepPurple.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplyToAllButton() {
    return PopupMenuButton<Map<String, dynamic>>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_all, color: Colors.blue.shade700, size: 14),
            SizedBox(width: 4),
            Text(
              'Apply All',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: {'width': 3.5, 'height': 4.5, 'unit': DimensionUnit.cm, 'count': 10},
          child: Text('Passport (3.5×4.5 cm) - 10 each'),
        ),
        PopupMenuItem(
          value: {'width': 2.5, 'height': 3.5, 'unit': DimensionUnit.cm, 'count': 10},
          child: Text('Stamp (2.5×3.5 cm) - 10 each'),
        ),
        PopupMenuItem(
          value: {'width': 2.0, 'height': 2.0, 'unit': DimensionUnit.inch, 'count': 10},
          child: Text('2×2 inch - 10 each'),
        ),
        PopupMenuItem(
          value: {'width': 4.0, 'height': 6.0, 'unit': DimensionUnit.inch, 'count': 10},
          child: Text('4×6 inch - 10 each'),
        ),
      ],
      onSelected: (value) {
        setState(() {
          for (int i = 0; i < _customDimensions.length; i++) {
            _customDimensions[i].width = value['width'];
            _customDimensions[i].height = value['height'];
            _customDimensions[i].unit = value['unit'];
            _customWidthControllers[i].text = value['width'].toString();
            _customHeightControllers[i].text = value['height'].toString();
            _photoControllers[i].text = value['count'].toString();
            _individualPhotoCounts[i] = value['count'];
          }
        });
      },
    );
  }

  Widget _buildIndividualCustomPhotoCard(File image, int index) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          // Photo header
          Row(
            children: [
              // Photo thumbnail
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo ${index + 1}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Custom dimensions & count',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Copy from previous button (if not first)
              if (index > 0)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _customDimensions[index].width = _customDimensions[index - 1].width;
                      _customDimensions[index].height = _customDimensions[index - 1].height;
                      _customDimensions[index].unit = _customDimensions[index - 1].unit;
                      _customWidthControllers[index].text = _customWidthControllers[index - 1].text;
                      _customHeightControllers[index].text = _customHeightControllers[index - 1].text;
                      _photoControllers[index].text = _photoControllers[index - 1].text;
                      _individualPhotoCounts[index] = _individualPhotoCounts[index - 1];
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Copy Above',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 16),

          // Unit Selection
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: DimensionUnit.values.map((unit) {
                bool isSelected = _customDimensions[index].unit == unit;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _updateCustomDimension(index, unit: unit);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          _getUnitSymbol(unit),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.blue.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 16),

          // Dimensions Row
          Row(
            children: [
              // Width
              Expanded(
                flex: 2,
                child: _buildDimensionTextField(
                  'Width',
                  'Width',
                  _customWidthControllers[index],
                  _getUnitSymbol(_customDimensions[index].unit),
                  onChanged: (value) {
                    double? width = double.tryParse(value);
                    if (width != null) {
                      _updateCustomDimension(index, width: width);
                    }
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              // Height
              Expanded(
                flex: 2,
                child: _buildDimensionTextField(
                  'Height',
                  'Height',
                  _customHeightControllers[index],
                  _getUnitSymbol(_customDimensions[index].unit),
                  onChanged: (value) {
                    double? height = double.tryParse(value);
                    if (height != null) {
                      _updateCustomDimension(index, height: height);
                    }
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // PROMINENT PHOTO COUNT SECTION - NEW
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number of Photos',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                _buildCountTextField(
                  'Count',
                  'Enter count',
                  _photoControllers[index],
                      (value) => _updatePhotoCount(index, value),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // PHOTO COUNT DISPLAY - NEW PROMINENT SECTION
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Photos to generate:',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_individualPhotoCounts[index]}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Quick dimension presets for this photo
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildDimensionPreset('Passport', 3.5, 4.5, DimensionUnit.cm, index),
              _buildDimensionPreset('Stamp', 2.5, 3.5, DimensionUnit.cm, index),
              _buildDimensionPreset('2×2"', 2.0, 2.0, DimensionUnit.inch, index),
              _buildDimensionPreset('4×6"', 4.0, 6.0, DimensionUnit.inch, index),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionPreset(String label, double width, double height, DimensionUnit unit, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _customDimensions[index].unit = unit;
          _customDimensions[index].width = width;
          _customDimensions[index].height = height;
          _customWidthControllers[index].text = width.toString();
          _customHeightControllers[index].text = height.toString();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionTextField(
      String label,
      String hint,
      TextEditingController controller,
      String unit, {
        Function(String)? onChanged,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: InputBorder.none,
          suffixText: unit,
          suffixStyle: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        onChanged: onChanged ?? (value) {
          setState(() {}); // Refresh to update validation
        },
      ),
    );
  }

  Widget _buildIndividualPhotoCountSection(List<File> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with bulk actions
        Row(
          children: [
            Expanded(
              child: Text(
                'Set count for each photo:',
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Quick set buttons
            _buildQuickSetButton('5', 5),
            SizedBox(width: 4),
            _buildQuickSetButton('10', 10),
            SizedBox(width: 4),
            _buildQuickSetButton('20', 20),
          ],
        ),
        SizedBox(height: 12),

        // Individual photo count inputs
        ...List.generate(images.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Photo thumbnail
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Photo label and count input
                Expanded(
                  child: _buildCountTextField(
                    'Photo ${index + 1}',
                    'Enter count',
                    _photoControllers[index],
                        (value) => _updatePhotoCount(index, value),
                  ),
                ),
              ],
            ),
          );
        }),

        // Summary
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total photos to generate:',
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$_totalPhotoCount',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSetButton(String label, int value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          for (int i = 0; i < _photoControllers.length; i++) {
            _photoControllers[i].text = value.toString();
            _individualPhotoCounts[i] = value;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.deepPurple,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
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