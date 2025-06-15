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
  File? _image;
  bool _isPickHovered = false;
  bool _isNextHovered = false;

// Simplified approach - ImagePicker handles permissions internally
  Future<void> _pickAndCropImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
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
            _image = File(croppedFile.path);
          });
        }
      }
    } catch (error) {
      print("Error picking or cropping image: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing media. Please check app permissions in settings.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select and Crop Image',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold
            )
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: Color(0xFFE8E8F5),
        width: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight - 48, // Account for appbar and padding
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flexible Image Display Section
                    Flexible(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.35, // Reduced from 0.4
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
                          child: _image != null
                              ? ImageDisplay(image: _image!)
                              : Center(
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
                                  'No image selected',
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30), // Reduced from 40

                    // Buttons Row
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pick and Crop Button
                          GestureDetector(
                            onTap: _pickAndCropImage,
                            onTapDown: (_) {
                              setState(() {
                                _isPickHovered = true;
                              });
                            },
                            onTapUp: (_) {
                              setState(() {
                                _isPickHovered = false;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                _isPickHovered = false;
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              width: 130,
                              height: 110,
                              decoration: BoxDecoration(
                                color: _isPickHovered ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isPickHovered ? Colors.purple.withOpacity(0.6) : Colors.black12,
                                    blurRadius: _isPickHovered ? 8 : 4,
                                    spreadRadius: _isPickHovered ? 2 : 1,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      size: 32,
                                      color: Colors.deepPurple,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Pick & Crop\nImage",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 12),

                          // Next Button (only visible if an image is selected)
                          if (_image != null)
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/selectSize',
                                  arguments: _image,
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
                                width: 130,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: _isNextHovered ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isNextHovered ? Colors.purple.withOpacity(0.6) : Colors.black12,
                                      blurRadius: _isNextHovered ? 8 : 4,
                                      spreadRadius: _isNextHovered ? 2 : 1,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 32,
                                        color: Colors.deepPurple,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Continue",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Proceed to select size",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54,
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

                    // Add some bottom spacing
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}