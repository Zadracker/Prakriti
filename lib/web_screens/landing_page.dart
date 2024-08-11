import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:prakriti/web_screens/web_authentication/web_login.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  void _launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        setState(() {
        });
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        setState(() {
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                
                backgroundColor: Colors.black,
                floating: true,
                pinned: false,
                automaticallyImplyLeading: false,
                expandedHeight: 80.0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'lib/assets/Prakriti_logo.svg',
                              height: 40.0,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Prakriti',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const WebLogin()),);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black, 
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Reduce the radius for a rounded square button
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Adjust padding for square-like shape
                          ),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                 RichText(
                                  textAlign: TextAlign.left,
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Ecofriendly\nwithout\n',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 60,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'overwhelm',
                                        style: TextStyle(
                                          color: Colors.green, // Set "overwhelm" to green
                                          fontSize: 60,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Be aware and gamify sustainable\nliving without the overwhelm',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: MouseRegion(
                                onHover: (event) {
                                  // Handle hover to add perspective shift or glow effect
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Image.asset(
                                    'lib/assets/landing_page_assets/hero_large.png',
                                    height: MediaQuery.of(context).size.height * 1.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center the text within the container
                        children: [
                          const Text(
                            'Why is it so overwhelming to live sustainably?',
                            textAlign: TextAlign.center, // Center the main title text
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Even if you\'re deeply committed to making eco-friendly choices…',
                            textAlign: TextAlign.center, // Center the subtitle text
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Center the text within each column
                          children: [
                            const Text(
                              '1',
                              textAlign: TextAlign.center, // Center the number text
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "...if you're not aware of the right steps\n ➡️ living sustainably can feel\n unattainable",
                              textAlign: TextAlign.center, // Center the body text
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Center the text within each column
                          children: [
                            const Text(
                              '2',
                              textAlign: TextAlign.center, // Center the number text
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "...if you can't apply knowledge in life,\n➡️ making impact is impossible",
                              textAlign: TextAlign.center, // Center the body text
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Center the text within each column
                          children: [
                            const Text(
                              '3',
                              textAlign: TextAlign.center, // Center the number text
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "...if you don’t have a community to help you,\n➡️ it’s really hard to keep going",
                              textAlign: TextAlign.center, // Center the body text
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                   Container(
                      padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 16.0), // Added space above
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Centered the text
                        children: [
                          const Text(
                            'How we make it possible?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Features built in Prakriti to help you live sustainably',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Section 1
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Image.asset(
                              'lib/assets/landing_page_assets/scan.png',
                              height: MediaQuery.of(context).size.height * 0.9,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Small white card with grey text above the title
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '# Awareness',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Scan for Eco-Friendly Choices',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Make informed decisions with our integrated tool, scanning and providing guidance for eco-friendly actions.',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Section 2
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Small white card with grey text above the title
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '# Awareness',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Your Eco Guide, On-Demand',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Get instant help and advice from our chatbot, guiding you through any eco-related challenges.',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Image.asset(
                              'lib/assets/landing_page_assets/gemini.png',
                              height: MediaQuery.of(context).size.height * 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Section 3
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Image.asset(
                              'lib/assets/landing_page_assets/news.png',
                              height: MediaQuery.of(context).size.height * 0.9,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Small white card with grey text above the title
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '# Awareness',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Stay Updated with Eco News',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Get the latest environmental news delivered straight to your feed, keeping you informed and engaged.',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Section 4
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Small white card with grey text above the title
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '# Gamification',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Conquer Special Eco Tasks',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Engage in gamified tasks created by eco advocates, earning points while supporting environmental efforts.',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Image.asset(
                              'lib/assets/landing_page_assets/tasks.png',
                              height: MediaQuery.of(context).size.height * 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Section 5
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Image.asset(
                              'lib/assets/landing_page_assets/quiz.png', // Gamification image
                              height: MediaQuery.of(context).size.height * 0.9,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Small white card with grey text above the title
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '# Gamification',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Learn and Win with Quizzes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Stay eco-conscious through fun, interactive quizzes that educate and entertain.\n\n*Freshly generated through Gemini AI',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Section 6
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Small white card with grey text above the title
                                Card(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '# Community',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Build Your Eco Community',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Connect with fellow eco warriors in our integrated forum, fostering a supportive and tight-knit community',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Image.asset(
                              'lib/assets/landing_page_assets/Forum.png',
                              height: MediaQuery.of(context).size.height * 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      // Inside the Container where you have 'FAQs' section
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center all text horizontally
                        children: [
                          const Text(
                            'Frequently Asked Questions',
                            textAlign: TextAlign.center, // Center the text within the widget
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Explore the answers to common queries and make the most of Prakriti',
                            textAlign: TextAlign.center, // Center the text within the widget
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Add the ExpansionTile widgets for FAQs
                          const ExpansionTile(
                            title: Center(
                              child: Text(
                                'What accessibility features does Prakriti app offer?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Prakriti is designed with inclusivity and accessibility in mind. It offers customizable features such as font options (OpenSans and OpenDyslexic) to support users with dyslexia or other learning disabilities, adjustable font size for enhanced readability, and text-to-speech and speech-to-text functionality for added convenience. The app's user interface employs a simple, high-contrast design that is both visually appealing and accessible to users with color blindness.",
                                  textAlign: TextAlign.center, // Center the text within the widget
                                ),
                              ),
                            ],
                          ),
                          const ExpansionTile(
                            title: Center(
                              child: Text(
                                'How does the Prakriti contribute meaningfully to environmental sustainability?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Prakriti promotes environmental sustainability by empowering users to make informed, eco-friendly choices. The app offers tools and resources to incorporate sustainable practices into daily life, while gamification and a supportive community foster long-term commitment to a greener lifestyle.',
                                  textAlign: TextAlign.center, // Center the text within the widget
                                ),
                              ),
                            ],
                          ),
                          const ExpansionTile(
                            title: Center(
                              child: Text(
                                "How does this app contribute meaningfully to improving users' lives?",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Prakriti empowers users to lead a greener lifestyle, creating a positive impact not only in their own lives but also within their communities and the environment. By motivating and connecting users through eco-friendly activities, Prakriti encourages individuals to improve themselves while collectively working towards a more sustainable world.\n\nIn essence, Prakriti enriches lives by making sustainability achievable, enabling users to contribute to a healthier planet while fostering a supportive community that celebrates every step toward meaningful change.",
                                  textAlign: TextAlign.center, // Center the text within the widget
                                ),
                              ),
                            ],
                          ),
                          const ExpansionTile(
                            title: Center(
                              child: Text(
                                'How can my organization leverage Prakriti?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Prakriti offers a unique 'Eco Advocate' role exclusively for organizations and influential eco-leaders. This role empowers you to create Special Tasks and engage directly with the Prakriti community. By leveraging our platform, your organization can boost participation in eco-initiatives, optimize resource allocation, and significantly reduce recruitment and advertising costs for volunteer programs.",
                                  textAlign: TextAlign.center, // Center the text within the widget
                                ),
                              ),
                            ],
                          ),
                           const ExpansionTile(
                            title: Center(
                              child: Text(
                                'Who is Prakriti for?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Prakriti is for everyone who aspires to live an eco-conscious life. It's designed to help users make informed decisions and integrate sustainable habits into their daily routines. By providing a platform for eco-conscious individuals, Prakriti reduces the resource and cost burden on eco-organizations, connecting them with a community of engaged participants. With its gamification and community features, Prakriti makes eco-activities more accessible and appealing, empowering users to contribute meaningfully to a sustainable future.",
                                  textAlign: TextAlign.center, 
                                ),
                              ),
                            ],
                          ),
                          const ExpansionTile(
                            title: Center(
                              child: Text(
                                'Why does Prakriti only have dark mode?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Dark mode is not just visually appealing; it's also environmentally conscious. By significantly reducing energy consumption, especially on OLED screens, dark mode helps conserve battery life and minimize the strain on power grids. Opting for dark mode is a small step that contributes to a larger goal of reducing our carbon footprint.",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                           const ExpansionTile(
                            title: Center(
                              child: Text(
                                'What are the upcoming developments for Prakriti?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Prakriti is still in its infancy and more features are absolutely planned for the future - updates will be announced on socials",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // CTA Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: Colors.grey[900], // Background color of the card
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // Rounded corners for the card
                        ),
                        elevation: 8, // Add shadow to the card
                        child: Container(
                          padding: const EdgeInsets.all(32.0),
                          height: MediaQuery.of(context).size.height * 0.8, // 50% of screen height
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Are you Ready?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Get started with Prakriti today and take your first step towards sustainable living!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MouseRegion(
                                    onHover: (event) {
                                      // Show tooltip or effect for web
                                    },
                                    child: Card(
                                      color: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                           Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const WebLogin()),);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16.0),
                                          child: const Column(
                                            children: [
                                              Icon(Icons.computer, size: 40, color: Colors.white),
                                              SizedBox(height: 10),
                                              Text(
                                                'Continue to Prakriti Web',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.black),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  MouseRegion(
                                    onHover: (event) {
                                      // Show tooltip or effect for web
                                    },
                                    child: Card(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          // Action for Android icon
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16.0),
                                          child: const Column(
                                            children: [
                                              Icon(Icons.phone_android, size: 40, color: Colors.green),
                                              SizedBox(height: 10),
                                              Text(
                                                'Download Prakriti Android',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.black),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.black,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Contact Us',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Email: zayyandalai@gmail.com',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Follow us on social media:',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _launchURL('https://www.linkedin.com/in/zayyan-dalai/');
                                },
                                child: const Text(
                                  'LinkedIn',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 20),
                              TextButton(
                                onPressed: () {
                                  _launchURL('https://www.instagram.com/zayyan_dalai/');
                                },
                                child: const Text(
                                  'Instagram',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}