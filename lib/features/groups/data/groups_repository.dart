import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/group_model.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final groupsProvider =
    StateNotifierProvider<GroupsNotifier, AsyncValue<List<GroupModel>>>((ref) {
  return GroupsNotifier(ref.read(apiClientProvider));
});

// Convenience: unwrap to list (empty while loading)
final groupsListProvider = Provider<List<GroupModel>>((ref) {
  return ref.watch(groupsProvider).valueOrNull ?? [];
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class GroupsNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  GroupsNotifier(this._api) : super(const AsyncValue.data([]));

  final ApiClient _api;

  String get _currentUserId {
    if (!SupabaseConfig.isConfigured) return 'local';
    return Supabase.instance.client.auth.currentUser?.id ?? 'local';
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.get<List<dynamic>>('/groups');
      final groups = (res.data ?? [])
          .map((j) => GroupModel.fromJson(
              j as Map<String, dynamic>, _currentUserId))
          .toList();
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<GroupModel> createGroup({
    required String name,
    required String emoji,
  }) async {
    final res = await _api.post<Map<String, dynamic>>('/groups', data: {
      'name': name,
      'emoji': emoji,
    });
    final group =
        GroupModel.fromJson(res.data!, _currentUserId);
    state = state.whenData((list) => [group, ...list]);
    return group;
  }

  Future<GroupModel?> joinGroupFromInvite(
      String groupId, String token) async {
    final res = await _api
        .post<Map<String, dynamic>>('/invites/$token/join');
    final group =
        GroupModel.fromJson(res.data!, _currentUserId);
    state = state.whenData((list) {
      final exists = list.any((g) => g.id == group.id);
      return exists
          ? [for (final g in list) if (g.id == group.id) group else g]
          : [group, ...list];
    });
    return group;
  }
}
