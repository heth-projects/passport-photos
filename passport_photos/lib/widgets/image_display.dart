import 'dart:io';
import 'package:flutter/material.dart';

class ImageDisplay extends StatelessWidget {
  final File image;
  const ImageDisplay({Key? key, required this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: Image.file(
        image,
        fit: BoxFit.contain,
      ),
    );
  }
}
