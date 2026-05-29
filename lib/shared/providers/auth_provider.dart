import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';

class AuthStateSnapshot {
  const AuthStateSnapshot({
    required this.session,
    required this.hasProfile,
    required this.isSupabaseConfigured,
  });

  final Session? session;
  final bool hasProfile;
  final bool isSupabaseConfigured;

  bool get isAuthenticated => session != null;
}

final authStateProvider = StreamProvider<AuthStateSnapshot>((ref) async* {
  if (!SupabaseConfig.isConfigured) {
    yield const AuthStateSnapshot(
      session: null,
      hasProfile: false,
      isSupabaseConfigured: false,
    );
    return;
  }

  final client = Supabase.instance.client;

  AuthStateSnapshot readSnapshot(Session? session) {
    return AuthStateSnapshot(
      session: session,
      hasProfile: session != null, // backend auto-upserts on first request
      isSupabaseConfigured: true,
    );
  }

  yield readSnapshot(client.auth.currentSession);

  yield* client.auth.onAuthStateChange.map((event) {
    return readSnapshot(event.session);
  });
});

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions();
});


class AuthActions {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
  }

  Future<void> signInWithOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyOtp({required String phone, required String token}) async {
    await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: token,
    );
  }

  Future<void> completeOnboarding({
    required String userId,
    required String name,
    String? phone,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'name': name,
      'phone': phone,
    });
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await _client.auth.signOut();
    }
  }
}
