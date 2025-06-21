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
    return Scaffold(
      appBar: AppBar(
        title: Text('Select and Crop Images',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold
            )
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
      body: Container(
        color: Color(0xFFE8E8F5),
        width: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Images Display Section
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                    minHeight: 200,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _images.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 80,
                            color: Colors.deepPurple.withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No images selected',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 18,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add images to get started',
                            style: TextStyle(
                                color: Colors.black38,
                                fontSize: 14
                            ),
                          ),
                        ],
                      ),
                    )
                        : Column(
                      children: [
                        // Images count header
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
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
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                              itemCount: _images.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImageIndex = _selectedImageIndex == index ? null : index;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedImageIndex == index
                                                ? Colors.deepPurple
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            _images[index],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Remove button
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          width: 24,
                                          height: 24,
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
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Selection indicator
                                    if (_selectedImageIndex == index)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Selected',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add Multiple Images Button
                    GestureDetector(
                      onTap: _isProcessing ? null : _pickAndCropImages,
                      child: Container(
                        width: 120,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isProcessing
                              ? Colors.grey.withOpacity(0.5)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isProcessing
                                ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                              ),
                            )
                                : Icon(
                              Icons.photo_library,
                              size: 28,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(height: 8),
                            Text(
                              _isProcessing ? "Processing..." : "Add Multiple\nImages",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _isProcessing ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Add Single Image Button
                    GestureDetector(
                      onTap: _isProcessing ? null : _addSingleImage,
                      child: Container(
                        width: 120,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isProcessing
                              ? Colors.grey.withOpacity(0.5)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 28,
                              color: _isProcessing ? Colors.grey : Colors.deepPurple,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add Single\nImage",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _isProcessing ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Next Button (only visible if images are selected)
                    if (_images.isNotEmpty) ...[
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/selectSize',
                            arguments: _images, // Pass the list of images
                          );
                        },
                        onTapDown: (_) {
                          setState(() {
                            _isNextHovered = true;
                          });
                        },
                        onTapUp: (_) {
                          setState(() {
                            _isNextHovered = false;
                          });
                        },
                        onTapCancel: () {
                          setState(() {
                            _isNextHovered = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 120,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _isNextHovered
                                ? Colors.deepPurple.withOpacity(0.9)
                                : Colors.deepPurple,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: _isNextHovered
                                    ? Colors.deepPurple.withOpacity(0.6)
                                    : Colors.black12,
                                blurRadius: _isNextHovered ? 8 : 4,
                                spreadRadius: _isNextHovered ? 2 : 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                size: 28,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Continue",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Next Step",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}