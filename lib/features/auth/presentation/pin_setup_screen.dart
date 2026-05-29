import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/gradient_button.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String? _confirmPin;
  bool _settingConfirm = false;

  void _onDigit(String d) {
    if (_pin.length < 4) {
      setState(() => _pin += d);
      if (_pin.length == 4 && !_settingConfirm) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          setState(() {
            _confirmPin = _pin;
            _pin = '';
            _settingConfirm = true;
          });
        });
      } else if (_pin.length == 4 && _settingConfirm) {
        _submit();
      }
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _submit() async {
    if (_pin == _confirmPin) {
      await ref.read(authServiceProvider).setPin(_pin);
      if (mounted) context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match. Try again.')),
      );
      setState(() {
        _pin = '';
        _confirmPin = null;
        _settingConfirm = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 640;
            final topSpacing = compact ? 8.0 : 24.0;
            final sectionGap = compact ? 20.0 : 32.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                  SizedBox(height: topSpacing),
                  Icon(
                    Icons.lock_rounded,
                    size: compact ? 52 : 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  Text(
                    _settingConfirm ? 'Confirm your PIN' : 'Set a 4-digit PIN',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Optional — secure your expense data',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: sectionGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _pin.length
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: sectionGap),
                  _PinPad(
                    compact: compact,
                    onDigit: _onDigit,
                    onBackspace: _backspace,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: ref.read(authServiceProvider).canUseBiometrics(),
                    builder: (context, snap) {
                      if (snap.data != true) return const SizedBox.shrink();
                      return GradientButton(
                        label: 'Enable Biometric Unlock',
                        icon: Icons.fingerprint_rounded,
                        onPressed: () async {
                          await ref
                              .read(authServiceProvider)
                              .setBiometricEnabled(true);
                          if (context.mounted) context.go('/');
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onDigit,
    required this.onBackspace,
    this.compact = false,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: compact ? 1.55 : 1.35,
        mainAxisSpacing: compact ? 4 : 8,
        crossAxisSpacing: compact ? 4 : 8,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        if (key.isEmpty) return const SizedBox.shrink();
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => key == '⌫' ? onBackspace() : onDigit(key),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                key,
                style: TextStyle(
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
