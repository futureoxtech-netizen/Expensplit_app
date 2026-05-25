import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/primary_button.dart';

class _Slide {
  const _Slide(this.title, this.subtitle, this.icon, this.colors);
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      'Track expenses\nbeautifully',
      'Split bills with friends, family, roommates and trips — clean, simple, and fair.',
      Icons.payments_rounded,
      [Color(0xFF6C5CE7), Color(0xFF00B894)],
    ),
    _Slide(
      'Smart settlements',
      'See who owes whom at a glance with debt simplification that minimises transfers.',
      Icons.handshake_rounded,
      [Color(0xFF44C4FF), Color(0xFF6C5CE7)],
    ),
    _Slide(
      'Real-time everything',
      'Live sync across devices, instant notifications, and rich analytics for your money.',
      Icons.insights_rounded,
      [Color(0xFFFF9F43), Color(0xFFE17055)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 24, 0),
              child: BrandLockup(logoSize: 38, wordmarkFontSize: 20),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _OnboardSlide(slide: _slides[i]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == _index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _index == _slides.length - 1 ? 'Get started' : 'Next',
                    onPressed: () {
                      if (_index < _slides.length - 1) {
                        _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                      } else {
                        context.go('/register');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('I already have an account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: slide.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: slide.colors.first.withOpacity(0.45),
                      blurRadius: 50,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Icon(slide.icon, size: 96, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(slide.title,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
