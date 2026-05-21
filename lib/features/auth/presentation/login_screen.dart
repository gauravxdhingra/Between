import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authActionsProvider).signInWithOtp(_phoneController.text.trim());
      setState(() {
        _otpSent = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authActionsProvider).verifyOtp(
            phone: _phoneController.text.trim(),
            token: _otpController.text.trim(),
          );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F7F4), Color(0xFFE8E6FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text('Between', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Shared money, zero awkwardness.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: kTextSecondary),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+91 98765 43210',
                    labelText: 'Phone number',
                  ),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '123456',
                      labelText: 'OTP',
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: kNegative)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading || !SupabaseConfig.isConfigured
                      ? null
                      : (_otpSent ? _verifyOtp : _sendOtp),
                  child: Text(_otpSent ? 'Verify OTP' : 'Continue with Phone'),
                ),
                if (!SupabaseConfig.isConfigured) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define to enable sign-in.',
                    style: TextStyle(color: kTextSecondary),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: null,
                  child: const Text('Sign in with Google (Phase 1.1)'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
