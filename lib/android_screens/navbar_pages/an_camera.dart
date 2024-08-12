import 'package:flutter/material.dart';
import 'package:prakriti/android_screens/cam_page/scan_page.dart';
import 'package:prakriti/theme.dart';

/// The EcoCameraPage displays a user interface for eco-related scanning actions.
/// It includes description rows for each scanning feature and floating action buttons
/// to navigate to the respective scan pages.
class EcoCameraPage extends StatelessWidget {
  const EcoCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Positioned widget to place top descriptions with icons
          Positioned(
            top: 40.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                // Description for scanning products
                _buildDescriptionRow(
                  context,
                  Icons.camera_alt_rounded,
                  'Scan Product',
                  'Scan products for eco-friendliness.',
                ),
                const SizedBox(height: 8.0),
                // Description for scanning pollution
                _buildDescriptionRow(
                  context,
                  Icons.remove_red_eye_rounded,
                  'Scan Pollution',
                  'Scan pollution levels in your area.',
                ),
                const SizedBox(height: 8.0),
                // Description for recycling scans
                _buildDescriptionRow(
                  context,
                  Icons.autorenew_rounded,
                  'Recycle Scan',
                  'Scan items to check if they are recyclable.',
                ),
                const SizedBox(height: 8.0),
                // Description for getting eco-info
                _buildDescriptionRow(
                  context,
                  Icons.info_rounded,
                  'Info',
                  'Get eco-info on the image',
                ),
              ],
            ),
          ),
          // Positioned widget to place floating action buttons at the bottom
          Positioned(
            bottom: 40.0,
            left: 16.0,
            right: 16.0,
            child: Container(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row with two floating action buttons
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
                  // Row with two more floating action buttons
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

  /// Builds a row with an icon and a description for scanning features.
  /// 
  /// Parameters:
  /// - [context]: The BuildContext for the widget.
  /// - [icon]: The icon to display.
  /// - [label]: The label for the description.
  /// - [description]: The text description for the feature.
  Widget _buildDescriptionRow(BuildContext context, IconData icon, String label, String description) {
    return Row(
      children: [
        // Icon representing the scanning feature
        Icon(icon, size: 30.0, color: AppTheme.darkAccentColor),
        const SizedBox(width: 8.0),
        // Expanded widget to allow text to wrap if necessary
        Expanded(
          child: Text(
            description,
            style: const TextStyle(color: AppTheme.darkHeadingColor, fontSize: 14.0),
          ),
        ),
      ],
    );
  }

  /// Builds a floating action button with an icon and a label.
  /// 
  /// Parameters:
  /// - [context]: The BuildContext for the widget.
  /// - [icon]: The icon to display on the button.
  /// - [label]: The label for the button.
  Widget _buildFloatingButton(BuildContext context, IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: 160.0,
        height: 160.0,
        color: AppTheme.darkAccentColor, // Use dark theme accent color for button background
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              navigateToScanPage(context, label); // Navigate to ScanPage with the corresponding action
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon for the floating button
                Icon(icon, size: 60.0, color: AppTheme.darkHeadingColor), // Use dark theme heading color
                const SizedBox(height: 8.0),
                // Label for the floating button
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

  /// Navigates to the ScanPage with the specified action.
  /// 
  /// Parameters:
  /// - [context]: The BuildContext for navigation.
  /// - [action]: The label for the action to pass to the ScanPage.
  void navigateToScanPage(BuildContext context, String action) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanPage(prompt: action), // Pass the action label to ScanPage
      ),
    );
  }
}
