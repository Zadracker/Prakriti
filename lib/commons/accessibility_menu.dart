import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart';
import 'package:flutter_tts/flutter_tts.dart';  // Import the flutter_tts package

class AccessibilityMenu extends StatefulWidget {
  const AccessibilityMenu({super.key});

  @override
  _AccessibilityMenuState createState() => _AccessibilityMenuState();
}

class _AccessibilityMenuState extends State<AccessibilityMenu> {
  final AccessibilityPreferencesService _preferencesService = AccessibilityPreferencesService();
  final User? _user = FirebaseAuth.instance.currentUser;
  
  String _selectedFont = 'OpenSans';
  int _fontSize = 1;
  bool _readAloud = false;

  final FlutterTts _flutterTts = FlutterTts();  // Initialize FlutterTts

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_user != null) {
      Map<String, dynamic> preferences = await _preferencesService.getUserPreferences(_user.uid);
      setState(() {
        _selectedFont = preferences['font'];
        _fontSize = preferences['fontSize'];
        _readAloud = preferences['readAloud'];
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_user != null) {
      await _preferencesService.saveUserPreferences(
        _user.uid, _selectedFont, _fontSize, _readAloud
      );
    }
  }

  Future<void> _speak(String text) async {
    if (_readAloud) {
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Select Font'),
              subtitle: Text(_selectedFont),
              onTap: () async {
                String? font = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      title: const Text('Select Font'),
                      children: <Widget>[
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, 'OpenSans');
                          },
                          child: const Text('OpenSans'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, 'OpenDyslexic');
                          },
                          child: const Text('OpenDyslexic'),
                        ),
                      ],
                    );
                  },
                );
                if (font != null) {
                  setState(() {
                    _selectedFont = font;
                  });
                  await _savePreferences();
                }
              },
            ),
            ListTile(
              title: const Text('Font Size'),
              subtitle: Text('$_fontSize'),
              onTap: () async {
                int? size = await showDialog<int>(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      title: const Text('Select Font Size'),
                      children: <Widget>[
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, 1);
                          },
                          child: const Text('1X'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, 2);
                          },
                          child: const Text('2X'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context, 3);
                          },
                          child: const Text('3X'),
                        ),
                      ],
                    );
                  },
                );
                if (size != null) {
                  setState(() {
                    _fontSize = size;
                  });
                  await _savePreferences();
                }
              },
            ),
            SwitchListTile(
              title: const Text('Read Aloud'),
              value: _readAloud,
              onChanged: (bool value) async {
                setState(() {
                  _readAloud = value;
                });
                await _savePreferences();
              },
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _speak('This is an example of text-to-speech functionality.'),
              child: MouseRegion(
                onEnter: (_) => _speak('This is an example of text-to-speech functionality.'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Example Text: Tap or hover to hear this text read aloud.',
                    style: TextStyle(fontSize: _fontSize.toDouble() * 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
