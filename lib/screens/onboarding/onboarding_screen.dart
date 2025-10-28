import 'package:bsb_eats/screens/onboarding/pages/page1.dart';
import 'package:bsb_eats/screens/onboarding/pages/page2.dart';
import 'package:bsb_eats/screens/onboarding/pages/page3.dart';
import 'package:bsb_eats/screens/onboarding/pages/page4.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 1;

  Future<void> _onboardingFinished() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNewUser', false);
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: theme().primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _onboardingFinished(),
                    child: Text('Pular', style: theme().textTheme.titleSmall,)
                  ),
                  Text('$currentPage de 4', style: theme().textTheme.titleSmall,)
                ],
              ),
              const SizedBox(height: 50),
              Flexible(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => currentPage = value + 1),
                  children: const [
                    Page1(),
                    Page2(),
                    Page3(),
                    Page4(),
                  ],
                ),
              ),
              Center(
                child: SmoothPageIndicator(
                  controller: _pageController,  // PageController
                  count: 4,
                  effect: WormEffect(
                    dotWidth: 10,
                    dotHeight: 10,
                    activeDotColor: theme().colorScheme.surface
                  ),
                  onDotClicked: (index) => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeIn)
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if(currentPage == 4) {
                    _onboardingFinished();
                    return;
                  }
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme().primaryColor,
                  backgroundColor: theme().colorScheme.surfaceContainerLow,
                ),
                child: currentPage == 4 ? const Text('Finalizar') : const Text('Próximo')
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}