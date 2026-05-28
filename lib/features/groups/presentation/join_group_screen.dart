import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // Wait for auth to resolve
    final auth = await ref.read(authStateProvider.future);

    if (!mounted) return;

    if (!auth.isAuthenticated) {
      setState(() => _state = _JoinState.needsAuth);
      return;
    }

    _doJoin();
  }

  void _doJoin() {
    setState(() => _state = _JoinState.loading);

    final group = ref
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

    // Success — navigate to group detail, replacing this screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: switch (_state) {
            _JoinState.loading => const Center(
                child: CircularProgressIndicator(),
              ),

            _JoinState.needsAuth => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('💸', style: TextStyle(fontSize: 56),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Text(
                    "You've been invited",
                    style: amountStyle(size: 28)
                        .copyWith(color: kTextPrimary),
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
                  FilledButton(
                    onPressed: () {
                      // After sign-in the router will redirect back to /app,
                      // and pendingJoinProvider will trigger the join.
                      Navigator.of(context)
                          .pushReplacementNamed('/landing');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: kAccent,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Sign in to join',
                        style: TextStyle(fontSize: 16)),
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
                  Text(
                    'Invalid invite',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Something went wrong.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/app'),
                    child: const Text('Go home'),
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
