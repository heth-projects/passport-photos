import 'package:flutter/material.dart';
import 'package:passport_photos/screens/background_remover_screen.dart';
import 'package:passport_photos/screens/home_screen.dart';
import 'package:passport_photos/screens/image_picker_screen.dart';
import 'package:passport_photos/screens/pdf_preview_screen.dart';
import 'package:passport_photos/screens/size_selection_screen.dart';

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Passport Photo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/' : (context) => HomeScreen(),
        '/pickImage': (context) => ImagePickerScreen(),
        '/selectSize': (context) => SizeSelectionScreen(),
        '/previewPdf': (context) => PdfPreviewScreen(),
        '/backgroundRemover': (context) => BackgroundRemoverScreen(),
      },
    );
  }
}