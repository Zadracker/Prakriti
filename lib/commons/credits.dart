import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:prakriti/services/accessibility_preferences_service.dart';

class CreditsPage extends StatefulWidget {
  const CreditsPage({super.key});

  @override
  _CreditsPageState createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: () => _speak('OpenDyslexic Font'),
              child: Text(
                'OpenDyslexic Font',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: textSize(theme.textTheme.titleLarge?.fontSize ?? 20),
                  fontFamily: _font,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            GestureDetector(
              onTap: () => _speak(
                'The OpenDyslexic font is designed to help readability for some symptoms of dyslexia. '
                'It has heavy weighted bottoms to provide orientation and unique letter shapes to prevent confusion. '
                'Italic style is designed for emphasis while maintaining readability.'
              ),
              child: Text(
                'The OpenDyslexic font is designed to help readability for some symptoms of dyslexia. It has heavy weighted bottoms to provide orientation and unique letter shapes to prevent confusion. Italic style is designed for emphasis while maintaining readability.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textSize(theme.textTheme.bodyMedium?.fontSize ?? 16),
                  fontFamily: _font,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () => _speak('Thanks to:'),
              child: Text(
                'Thanks to:',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: textSize(theme.textTheme.titleLarge?.fontSize ?? 20),
                  fontFamily: _font,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            GestureDetector(
              onTap: () => _speak(
                '- Cheryl Marshall\n'
                '- Anonymous (MG)\n'
                '- Eric Bailey\n'
                '- Steven V James\n'
                '- @nguarracino\n'
                '- Plow Software, LLC\n\n'
                'Special thanks to:\n'
                '- @glyphsapp for Glyphs learning support.\n'
                '- Rob Carpenter of Oak Grove College for the Alta style.\n'
                '- TEDxGateway for the OpenDyslexic TEDx talk.'
              ),
              child: Text(
                '- Cheryl Marshall\n'
                '- Anonymous (MG)\n'
                '- Eric Bailey\n'
                '- Steven V James\n'
                '- @nguarracino\n'
                '- Plow Software, LLC\n\n'
                'Special thanks to:\n'
                '- @glyphsapp for Glyphs learning support.\n'
                '- Rob Carpenter of Oak Grove College for the Alta style.\n'
                '- TEDxGateway for the OpenDyslexic TEDx talk.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textSize(theme.textTheme.bodyMedium?.fontSize ?? 16),
                  fontFamily: _font,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () => _speak('License:'),
              child: Text(
                'License:',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: textSize(theme.textTheme.titleLarge?.fontSize ?? 20),
                  fontFamily: _font,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            GestureDetector(
              onTap: () => _speak(
                'The OpenDyslexic font is provided under the Bitstream Vera License. It can be copied, modified, and distributed freely under certain conditions. Full license details can be found on the OpenDyslexic website.'
              ),
              child: Text(
                'The OpenDyslexic font is provided under the Bitstream Vera License. It can be copied, modified, and distributed freely under certain conditions. Full license details can be found on the [OpenDyslexic website](http://opendyslexic.org).',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textSize(theme.textTheme.bodyMedium?.fontSize ?? 16),
                  fontFamily: _font,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () => _speak('Legal Declaration:'),
              child: Text(
                'Legal Declaration:',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: textSize(theme.textTheme.titleLarge?.fontSize ?? 20),
                  fontFamily: _font,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            GestureDetector(
              onTap: () => _speak(
                'To Whom It May Concern:\n\n'
                'I, Zayyan Dalai, hereby acknowledge and affirm the following regarding our use of the NEWS API:\n\n'
                'Use of NEWS API:\n'
                'We are utilizing the NEWS API to fetch publicly available news articles. The NEWS API is a service provided by [NEWS API Provider\'s Name], which allows us to retrieve news content from various sources.\n\n'
                'Non-Ownership of Articles:\n'
                'We do not claim ownership of the news articles, content, or any related materials obtained through the NEWS API. All articles and content provided through the API are the property of their respective publishers and owners. Our use of the NEWS API is solely for the purpose of accessing and displaying publicly available information.\n\n'
                'Compliance with Terms of Service:\n'
                'We acknowledge that the use of the NEWS API is subject to the Terms of Service (ToS) and legal licenses set forth by [NEWS API Provider\'s Name]. We agree to comply with all applicable terms and conditions outlined in these documents.\n\n'
                'Adherence to Legal Licenses:\n'
                'We are committed to adhering to all legal licenses and intellectual property rights associated with the news articles and content provided by the NEWS API. We will ensure that our use of the API and the articles obtained through it respects the rights of content creators and publishers.\n\n'
                'No Misrepresentation:\n'
                'We will not misrepresent, alter, or otherwise claim the content obtained from the NEWS API as our own. The articles and content will be presented in their original form, and we will make clear that they are sourced from the NEWS API.\n\n'
                'By using the NEWS API, we affirm our commitment to ethical practices and compliance with the API provider\'s terms and applicable legal requirements.\n\n'
                'For any questions or concerns regarding our use of the NEWS API or adherence to the ToS and legal licenses, please contact at zayyandalai@gmail.com'
              ),
              child: Text(
                'To Whom It May Concern:\n\n'
                'I, Zayyan Dalai, hereby acknowledge and affirm the following regarding our use of the NEWS API:\n\n'
                'Use of NEWS API:\n'
                'We are utilizing the NEWS API to fetch publicly available news articles. The NEWS API is a service provided by [NEWS API Provider\'s Name], which allows us to retrieve news content from various sources.\n\n'
                'Non-Ownership of Articles:\n'
                'We do not claim ownership of the news articles, content, or any related materials obtained through the NEWS API. All articles and content provided through the API are the property of their respective publishers and owners. Our use of the NEWS API is solely for the purpose of accessing and displaying publicly available information.\n\n'
                'Compliance with Terms of Service:\n'
                'We acknowledge that the use of the NEWS API is subject to the Terms of Service (ToS) and legal licenses set forth by [NEWS API Provider\'s Name]. We agree to comply with all applicable terms and conditions outlined in these documents.\n\n'
                'Adherence to Legal Licenses:\n'
                'We are committed to adhering to all legal licenses and intellectual property rights associated with the news articles and content provided by the NEWS API. We will ensure that our use of the API and the articles obtained through it respects the rights of content creators and publishers.\n\n'
                'No Misrepresentation:\n'
                'We will not misrepresent, alter, or otherwise claim the content obtained from the NEWS API as our own. The articles and content will be presented in their original form, and we will make clear that they are sourced from the NEWS API.\n\n'
                'By using the NEWS API, we affirm our commitment to ethical practices and compliance with the API provider\'s terms and applicable legal requirements.\n\n'
                'For any questions or concerns regarding our use of the NEWS API or adherence to the ToS and legal licenses, please contact at zayyandalai@gmail.com',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textSize(theme.textTheme.bodyMedium?.fontSize ?? 16),
                  fontFamily: _font,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
