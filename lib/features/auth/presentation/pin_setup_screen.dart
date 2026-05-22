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
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _settingConfirm ? 'Confirm your PIN' : 'Set a 4-digit PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Optional — secure your expense data',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
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
              const Spacer(),
              _PinPad(onDigit: _onDigit, onBackspace: _backspace),
              const SizedBox(height: 24),
              FutureBuilder<bool>(
                future: ref.read(authServiceProvider).canUseBiometrics(),
                builder: (context, snap) {
                  if (snap.data != true) return const SizedBox.shrink();
                  return GradientButton(
                    label: 'Enable Biometric Unlock',
                    icon: Icons.fingerprint_rounded,
                    onPressed: () async {
                      await ref.read(authServiceProvider).setBiometricEnabled(true);
                      if (mounted) context.go('/');
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({required this.onDigit, required this.onBackspace});

  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.4,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        if (key.isEmpty) return const SizedBox.shrink();
        return InkWell(
          onTap: () => key == '⌫' ? onBackspace() : onDigit(key),
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              key,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
          ),
        );
      },
    );
  }
}
