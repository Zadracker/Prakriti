import 'package:flutter/material.dart';
import 'package:prakriti/android_screens/cam_page/scan_page.dart';
import 'package:prakriti/theme.dart';

class EcoCameraPage extends StatelessWidget {
  const EcoCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your camera widget or background content goes here
          // Top text descriptions with icons
          Positioned(
            top: 40.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                _buildDescriptionRow(
                  context,
                  Icons.camera_alt_rounded,
                  'Scan Product',
                  'Scan products for eco-friendliness.',
                ),
                const SizedBox(height: 8.0),
                _buildDescriptionRow(
                  context,
                  Icons.remove_red_eye_rounded,
                  'Scan Pollution',
                  'Scan pollution levels in your area.',
                ),
                const SizedBox(height: 8.0),
                _buildDescriptionRow(
                  context,
                  Icons.autorenew_rounded,
                  'Recycle Scan',
                  'Scan items to check if they are recyclable.',
                ),
                const SizedBox(height: 8.0),
                _buildDescriptionRow(
                  context,
                  Icons.info_rounded,
                  'Info',
                  'Get eco-info on the image',
                ),
              ],
            ),
          ),
          // Floating action buttons grid
          Positioned(
            bottom: 40.0,
            left: 16.0,
            right: 16.0,
            child: Container(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFloatingButton(
                        context,
                        Icons.camera_alt_rounded,
                        'Scan Product',
                      ),
                      _buildFloatingButton(
                        context,
                        Icons.remove_red_eye_rounded,
                        'Scan Pollution',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFloatingButton(
                        context,
                        Icons.autorenew_rounded,
                        'Recycle Scan',
                      ),
                      _buildFloatingButton(
                        context,
                        Icons.info_rounded,
                        'Info',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDescriptionRow(BuildContext context, IconData icon, String label, String description) {
    return Row(
      children: [
        Icon(icon, size: 30.0, color: AppTheme.darkAccentColor),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(color: AppTheme.darkHeadingColor, fontSize: 14.0),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton(BuildContext context, IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: 160.0,
        height: 160.0,
        color: AppTheme.darkAccentColor, // Use dark theme accent color
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              navigateToScanPage(context, label); // Pass label as action
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 60.0, color: AppTheme.darkHeadingColor), // Use dark theme heading color
                const SizedBox(height: 8.0),
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.darkHeadingColor), // Use dark theme heading color
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void navigateToScanPage(BuildContext context, String action) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanPage(prompt: action),
      ),
    );
  }
}
