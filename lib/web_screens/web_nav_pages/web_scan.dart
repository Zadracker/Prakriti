import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:prakriti/services/eco_camera_services.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WebScanPage extends StatefulWidget {
  const WebScanPage({super.key});

  @override
  _WebScanPageState createState() => _WebScanPageState();
}

class _WebScanPageState extends State<WebScanPage> {
  Uint8List? _imageData;
  String _selectedAction = 'Scan Product';
  String _generatedOutput = '';
  bool _isImageSelected = false;

  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService();
  final FlutterTts _flutterTts = FlutterTts();

  int _fontSize = 1;
  String _font = 'OpenSans';
  bool _readAloud = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final preferences = await _preferencesService.getUserPreferences(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      _fontSize = preferences['fontSize'] ?? 1;
      _font = preferences['font'] ?? 'OpenSans';
      _readAloud = preferences['readAloud'] ?? false;
    });

    if (_readAloud) {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
    }
  }

  double textSize(double size) {
    switch (_fontSize) {
      case 2:
        return size * 2;
      case 3:
        return size * 3;
      default:
        return size;
    }
  }

  Future<void> _speak(String text) async {
    if (_readAloud) {
      await _flutterTts.speak(text);
    }
  }

  void _onActionSelected(String action) {
    setState(() {
      _selectedAction = action;
    });
  }

  void _chooseImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageData = result.files.single.bytes;
        _isImageSelected = true;
      });
    }
  }

  Future<void> _submitImage() async {
    if (_imageData != null) {
      final result = await submitImageToGemini(_imageData, _selectedAction);
      setState(() {
        _generatedOutput = result.output;
      });
      _speak(result.output);
    } else {
      setState(() {
        _generatedOutput = 'No image selected.';
      });
      _speak('No image selected.');
    }
  }

  String _getInfoText() {
    switch (_selectedAction) {
      case 'Scan Product':
        return 'Scan products for eco-friendliness.';
      case 'Scan Pollution':
        return 'Scan pollution levels in your area.';
      case 'Recycle Scan':
        return 'Scan items to check if they are recyclable.';
      case 'Info':
        return 'Get eco-info on the image';
      default:
        return 'Upload image to get information about it';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ToggleButtons(
                  constraints: const BoxConstraints.tightFor(width: 140, height: 50), // Fixed width and height for each button
                  isSelected: [
                    _selectedAction == 'Scan Product',
                    _selectedAction == 'Scan Pollution',
                    _selectedAction == 'Recycle Scan',
                    _selectedAction == 'Info',
                  ],
                  onPressed: (index) {
                    switch (index) {
                      case 0:
                        _onActionSelected('Scan Product');
                        _speak('Scan Product');
                        break;
                      case 1:
                        _onActionSelected('Scan Pollution');
                        _speak('Scan Pollution');
                        break;
                      case 2:
                        _onActionSelected('Recycle Scan');
                        _speak('Recycle Scan');
                        break;
                      case 3:
                        _onActionSelected('Info');
                        _speak('Info');
                        break;
                    }
                  },
                  borderRadius: BorderRadius.circular(30.0),
                  borderColor: Colors.blueGrey,
                  selectedBorderColor: Colors.green,
                  fillColor: Colors.green.withOpacity(0.2),
                  color: Colors.blueGrey,
                  selectedColor: Colors.green,
                  children: [
                    _buildSegmentedButtonText('Scan Product', theme),
                    _buildSegmentedButtonText('Scan Pollution', theme),
                    _buildSegmentedButtonText('Recycle Scan', theme),
                    _buildSegmentedButtonText('Info', theme),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: GestureDetector(
                      onTap: () => _speak(_generatedOutput),
                      child: Text(
                        _generatedOutput,
                        style: TextStyle(
                          fontSize: textSize(theme.textTheme.bodyMedium?.fontSize ?? 16),
                          fontFamily: _font,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _speak(_getInfoText()),
                            child: Text(
                              _getInfoText(),
                              style: TextStyle(
                                fontSize: textSize(theme.textTheme.bodyMedium?.fontSize ?? 14),
                                color: Colors.blueGrey,
                                fontFamily: _font,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,  // Add ellipsis if text overflows
                              softWrap: true,  // Enable wrapping
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const VerticalDivider(thickness: 1, width: 1),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_imageData != null) ...[
                  Image.memory(
                    _imageData!,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _chooseImage,
                  child: Text(
                    'Choose Image',
                    style: TextStyle(
                      fontSize: textSize(theme.textTheme.labelLarge?.fontSize ?? 14),
                      fontFamily: _font,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isImageSelected ? _submitImage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isImageSelected ? Colors.green : Colors.grey,
                  ),
                  child: Text(
                    'Scan',
                    style: TextStyle(
                      fontSize: textSize(theme.textTheme.labelLarge?.fontSize ?? 14),
                      fontFamily: _font,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedButtonText(String text, ThemeData theme) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: TextStyle(
          fontSize: textSize(theme.textTheme.bodyMedium?.fontSize ?? 14),
          fontFamily: _font,
        ),
      ),
    );
  }
}
