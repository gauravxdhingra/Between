import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/providers/auth_provider.dart';
import '../data/groups_repository.dart';
import 'group_detail_screen.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({
    super.key,
    required this.groupId,
    required this.token,
  });

  final String groupId;
  final String token;

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  _JoinState _state = _JoinState.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tryJoin();
  }

  Future<void> _tryJoin() async {
    final auth = await ref.read(authStateProvider.future);
    if (!mounted) return;
    if (!auth.isAuthenticated) {
      setState(() => _state = _JoinState.needsAuth);
      return;
    }
    _doJoin();
  }

  Future<void> _doJoin() async {
    setState(() => _state = _JoinState.loading);
    try {
      final group = await ref
          .read(groupsProvider.notifier)
          .joinGroupFromInvite(widget.groupId, widget.token);
      if (!mounted) return;
      if (group == null) {
        setState(() {
          _state = _JoinState.error;
          _errorMessage = 'This invite link is invalid or has expired.';
        });
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _JoinState.error;
        _errorMessage = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: kBgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: switch (_state) {
            _JoinState.loading => const Center(
                child: CircularProgressIndicator(color: kMint),
              ),

            _JoinState.needsAuth => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('💸',
                      style: TextStyle(fontSize: 56),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Text(
                    "You've been invited",
                    style: amountStyle(size: 28).copyWith(color: kTextPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to join the group and start splitting.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('/landing'),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: kMint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Sign in to join',
                          style: TextStyle(
                              color: kBgBase,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),

            _JoinState.error => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.link_off_rounded,
                      size: 56, color: kNegative),
                  const SizedBox(height: 24),
                  Text('Invalid invite',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Something went wrong.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('/app'),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: kBgElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kDivider),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Go home',
                          style: TextStyle(color: kTextSecondary)),
                    ),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}

enum _JoinState { loading, needsAuth, error }
