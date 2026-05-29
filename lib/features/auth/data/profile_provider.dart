import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

class ProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async => {};

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get<Map<String, dynamic>>('/profiles/me');
      state = AsyncData(res.data ?? {});
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateName(String name) async {
    final client = ref.read(apiClientProvider);
    final res = await client.put<Map<String, dynamic>>(
      '/profiles/me',
      data: {'name': name},
    );
    final updated = res.data ?? {};
    state = AsyncData({...?state.valueOrNull, ...updated});
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Map<String, dynamic>>(
  ProfileNotifier.new,
);
