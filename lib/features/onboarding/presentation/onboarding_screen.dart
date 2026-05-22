import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardPage(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Scan any UPI QR',
      subtitle: 'Point your camera at merchant QR codes — we parse UPI ID, amount, and merchant instantly.',
      gradient: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    ),
    _OnboardPage(
      icon: Icons.label_rounded,
      title: 'Tag before you pay',
      subtitle: 'Add amount and categories before opening GPay, PhonePe, or any UPI app. No SMS needed.',
      gradient: [Color(0xFF00CEC9), Color(0xFF74B9FF)],
    ),
    _OnboardPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Pay normally',
      subtitle: 'We redirect you to your preferred UPI app with amount and merchant prefilled.',
      gradient: [Color(0xFFFF7675), Color(0xFFFDCB6E)],
    ),
    _OnboardPage(
      icon: Icons.insights_rounded,
      title: 'Track automatically',
      subtitle: 'Confirm payment status when you return. Expenses sync to your premium dashboard.',
      gradient: [Color(0xFF00B894), Color(0xFF6C5CE7)],
    ),
  ];

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.notification,
    ].request();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await _requestPermissions();
    await ref.read(authServiceProvider).completeOnboarding();
    if (mounted) context.go('/pin-setup');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _page < _pages.length - 1 ? _finish : null,
                child: Text(_page < _pages.length - 1 ? 'Skip' : ''),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                dotColor: Colors.grey.withValues(alpha: 0.3),
                activeDotColor: AppColors.primary,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GradientButton(
                label: _page == _pages.length - 1 ? 'Get Started' : 'Continue',
                onPressed: () {
                  if (_page < _pages.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    _finish();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
