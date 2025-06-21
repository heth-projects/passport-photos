import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/image_display.dart';

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  List<File> _images = [];
  bool _isPickHovered = false;
  bool _isNextHovered = false;
  int? _selectedImageIndex;
  bool _isProcessing = false;
  static const int maxImages = 10; // Limit to prevent memory issues

  // Pick and crop multiple images
  Future<void> _pickAndCropImages() async {
    if (_isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        // Check if adding these images would exceed the limit
        if (_images.length + pickedFiles.length > maxImages) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum $maxImages images allowed. Please select fewer images.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        List<File> newImages = [];

        for (int i = 0; i < pickedFiles.length; i++) {
          XFile pickedFile = pickedFiles[i];

          // Show progress in UI
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Processing image ${i + 1} of ${pickedFiles.length}...'),
                duration: Duration(milliseconds: 500),
              ),
            );
          }

          CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            compressFormat: ImageCompressFormat.jpg,
            compressQuality: 85, // Reduced quality to manage file size
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Image ${i + 1}/${pickedFiles.length}',
                toolbarColor: Colors.deepPurple,
                toolbarWidgetColor: Colors.white,
                lockAspectRatio: false,
                hideBottomControls: true,
              ),
              IOSUiSettings(
                title: 'Crop Image ${i + 1}/${pickedFiles.length}',
              ),
            ],
          );

          if (croppedFile != null) {
            newImages.add(File(croppedFile.path));
          }
        }

        if (newImages.isNotEmpty) {
          setState(() {
            _images.addAll(newImages);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newImages.length} image${newImages.length > 1 ? 's' : ''} added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      print("Error picking or cropping images: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing media. Please check app permissions in settings.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Add single image
  Future<void> _addSingleImage() async {
    if (_isProcessing) return;

    if (_images.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxImages images allowed.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 85,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.deepPurple,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: false,
              hideBottomControls: true,
            ),
            IOSUiSettings(
              title: 'Crop Image',
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _images.add(File(croppedFile.path));
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      print("Error picking or cropping image: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing media. Please check app permissions in settings.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Remove image at index
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (_selectedImageIndex == index) {
        _selectedImageIndex = null;
      } else if (_selectedImageIndex != null && _selectedImageIndex! > index) {
        _selectedImageIndex = _selectedImageIndex! - 1;
      }
    });
  }

  // Clear all images with confirmation
  void _clearAllImages() {
    if (_images.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Images'),
          content: Text('Are you sure you want to remove all ${_images.length} images?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _images.clear();
                  _selectedImageIndex = null;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All images cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Reorder images (drag and drop functionality)
  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);

      // Update selected index if needed
      if (_selectedImageIndex == oldIndex) {
        _selectedImageIndex = newIndex;
      } else if (_selectedImageIndex != null) {
        if (_selectedImageIndex! > oldIndex && _selectedImageIndex! <= newIndex) {
          _selectedImageIndex = _selectedImageIndex! - 1;
        } else if (_selectedImageIndex! < oldIndex && _selectedImageIndex! >= newIndex) {
          _selectedImageIndex = _selectedImageIndex! + 1;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Images',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_images.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all, color: Colors.white),
              onPressed: _clearAllImages,
              tooltip: 'Clear all images',
            ),
        ],
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Images Display Section
                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.45, // Fixed height to prevent overflow
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _images.isEmpty
                          ? _buildEmptyState()
                          : _buildImageGrid(),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Image counter
                  if (_images.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_images.length} of $maxImages images selected',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action buttons row
                  Row(
                    children: [
                      // Add Multiple Images Button
                      Expanded(
                        child: _buildActionButton(
                          onTap: _isProcessing ? null : _pickAndCropImages,
                          icon: _isProcessing
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                            ),
                          )
                              : Icon(Icons.photo_library, size: 24, color: Colors.deepPurple),
                          label: _isProcessing ? "Processing..." : "Add Multiple",
                          isEnabled: !_isProcessing,
                          isPrimary: false,
                        ),
                      ),

                      SizedBox(width: 12),

                      // Add Single Image Button
                      Expanded(
                        child: _buildActionButton(
                          onTap: _isProcessing ? null : _addSingleImage,
                          icon: Icon(
                            Icons.add_photo_alternate,
                            size: 24,
                            color: _isProcessing ? Colors.grey : Colors.deepPurple,
                          ),
                          label: "Add Single",
                          isEnabled: !_isProcessing,
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ),

                  // Continue button (full width when images are present)
                  if (_images.isNotEmpty) ...[
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildActionButton(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/selectSize',
                            arguments: _images,
                          );
                        },
                        icon: Icon(Icons.arrow_forward, size: 24, color: Colors.white),
                        label: "Continue to Next Step",
                        isEnabled: true,
                        isPrimary: true,
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No images selected',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the buttons below to add images',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Text(
            '${_images.length} image${_images.length > 1 ? 's' : ''} selected',
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Images grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return _buildImageItem(index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(int index) {
    final isSelected = _selectedImageIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImageIndex = isSelected ? null : index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                _images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Selection indicator
            if (isSelected)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onTap,
    required Widget icon,
    required String label,
    required bool isEnabled,
    required bool isPrimary,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.deepPurple
              : (isEnabled ? Colors.white : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: Colors.grey[300]!),
          boxShadow: isPrimary
              ? [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : (isEnabled ? Colors.black87 : Colors.grey),
                  fontSize: 16,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}