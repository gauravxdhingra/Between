import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
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
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authActionsProvider).signInWithOtp(
            _phoneController.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authActionsProvider).verifyOtp(
            phone: _phoneController.text.trim(),
            token: _otpController.text.trim(),
          );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kBgBase,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),

                // ── Brand mark ──────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kMint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kMint.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('S',
                      style: TextStyle(
                          color: kMint,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 24),

                Text('Settle',
                    style: amountStyle(size: 36, color: kTextPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Shared money, zero awkwardness.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: kTextSecondary),
                ),

                const Spacer(flex: 1),

                // ── Phone input ──────────────────────────────────
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: '+91 98765 43210',
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                  ),
                  enabled: !_otpSent,
                ),

                if (_otpSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        letterSpacing: 6, fontWeight: FontWeight.w600),
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: '· · · · · ·',
                      labelText: 'OTP',
                      counterText: '',
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                    ),
                    autofocus: true,
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: kNegative)),
                ],

                const SizedBox(height: 20),

                // ── Primary CTA ──────────────────────────────────
                GestureDetector(
                  onTap: _loading || !SupabaseConfig.isConfigured
                      ? null
                      : (_otpSent ? _verifyOtp : _sendOtp),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    height: 54,
                    decoration: BoxDecoration(
                      color: (_loading || !SupabaseConfig.isConfigured)
                          ? kBgElevated
                          : kMint,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: (_loading || !SupabaseConfig.isConfigured)
                          ? null
                          : [
                              BoxShadow(
                                color: kMint.withValues(alpha: 0.28),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kBgBase,
                            ),
                          )
                        : Text(
                            _otpSent ? 'Verify OTP' : 'Continue',
                            style: TextStyle(
                              color: (!SupabaseConfig.isConfigured)
                                  ? kTextMuted
                                  : kBgBase,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                if (!SupabaseConfig.isConfigured) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Set SUPABASE_URL & SUPABASE_ANON_KEY via --dart-define to enable sign-in.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: kTextMuted),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 12),

                if (_otpSent)
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _otpSent = false;
                              _otpController.clear();
                              _error = null;
                            }),
                    child: const Text('Change number',
                        style: TextStyle(color: kTextSecondary)),
                  ),

                const Divider(color: kDivider, height: 32),

                // ── Skip (dev only) ──────────────────────────────
                GestureDetector(
                  onTap: _loading
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          ref.read(localTestModeProvider.notifier).state =
                              true;
                          context.go('/app');
                        },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: kBgElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kDivider),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Skip auth (dev mode)',
                      style: TextStyle(
                          color: kTextMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
