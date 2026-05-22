import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, this.onUnlocked});

  final VoidCallback? onUnlocked;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final auth = ref.read(authServiceProvider);
    if (auth.isBiometricEnabled && await auth.canUseBiometrics()) {
      final ok = await auth.authenticateWithBiometrics();
      if (ok && mounted) widget.onUnlocked?.call();
    }
  }

  Future<void> _verifyPin() async {
    if (_pin.length < 4) return;
    final ok = await ref.read(authServiceProvider).verifyPin(_pin);
    if (ok) {
      widget.onUnlocked?.call();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _pin = '';
      });
    }
  }

  void _onDigit(String d) {
    if (_pin.length < 4) {
      setState(() {
        _pin += d;
        _error = null;
      });
      if (_pin.length == 4) _verifyPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.lock_outline_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text('PayTrack', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Enter PIN to unlock', style: Theme.of(context).textTheme.bodyMedium),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
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
              IconButton(
                iconSize: 48,
                onPressed: _tryBiometric,
                icon: const Icon(Icons.fingerprint_rounded),
              ),
              const SizedBox(height: 16),
              _buildPad(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPad() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        if (key.isEmpty) return const SizedBox.shrink();
        return InkWell(
          onTap: () {
            if (key == '⌫') {
              setState(() {
                if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
              });
            } else {
              _onDigit(key);
            }
          },
          child: Center(
            child: Text(key, style: const TextStyle(fontSize: 26)),
          ),
        );
      },
    );
  }
}
