import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Passport Photo App',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold
            )
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera icon
            Icon(
              Icons.camera_alt,
              size: 100,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 30),

            // Heading text
            Text(
              "Choose a feature",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
            SizedBox(height: 30),

            // Feature cards in row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FeatureCard(
                  icon: Icons.photo_camera,
                  title: "Standard Photo",
                  description: "Take or select a photo for ID",
                  onTap: () {
                    Navigator.pushNamed(context, '/pickImage');
                  },
                ),
                SizedBox(width: 20),
                FeatureCard(
                  icon: Icons.edit,
                  title: "Background Remover",
                  description: "Change photo background color",
                  onTap: () {
                    Navigator.pushNamed(context, '/backgroundRemover');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// Feature card widget for the home screen options
class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Function() onTap;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  }) : super(key: key);

  @override
  _FeatureCardState createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isHovered = false;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 150,
        height: 200,
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? Colors.purple.withOpacity(0.6) : Colors.black12,
              blurRadius: _isHovered ? 8 : 4,
              spreadRadius: _isHovered ? 2 : 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 50,
                color: Colors.deepPurple,
              ),
              SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}