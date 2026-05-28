import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/group_model.dart';

final groupsProvider = StateNotifierProvider<GroupsNotifier, List<GroupModel>>((ref) {
  return GroupsNotifier();
});

class GroupsNotifier extends StateNotifier<List<GroupModel>> {
  GroupsNotifier()
      : super([
          GroupModel(
            id: 'sample-1',
            name: 'Goa Trip',
            emoji: '🏖️',
            memberCount: 4,
            netBalance: 2400,
            lastActivity: DateTime.now().subtract(const Duration(days: 1)),
            inviteToken: 'goa24',
            members: const ['You', 'Aarav', 'Nisha', 'Rohan'],
            expenses: [
              GroupExpensePreview(
                id: 'goa-e1',
                title: 'Airport cab',
                amount: 1600,
                paidBy: 'You',
                yourShare: 400,
                createdAt: DateTime.now().subtract(const Duration(hours: 6)),
              ),
              GroupExpensePreview(
                id: 'goa-e2',
                title: 'Beach dinner',
                amount: 3200,
                paidBy: 'Nisha',
                yourShare: 800,
                createdAt: DateTime.now().subtract(const Duration(days: 1)),
              ),
            ],
          ),
          GroupModel(
            id: 'sample-2',
            name: 'Flat Expenses',
            emoji: '🏠',
            memberCount: 3,
            netBalance: -850,
            lastActivity: DateTime.now().subtract(const Duration(days: 3)),
            inviteToken: 'flat09',
            members: const ['You', 'Kabir', 'Meera'],
            expenses: [
              GroupExpensePreview(
                id: 'flat-e1',
                title: 'Groceries',
                amount: 2400,
                paidBy: 'Kabir',
                yourShare: 800,
                createdAt: DateTime.now().subtract(const Duration(days: 2)),
              ),
            ],
          ),
        ]);

  final _uuid = const Uuid();

  GroupModel createGroup({required String name, required String emoji}) {
    final group = GroupModel(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      memberCount: 1,
      netBalance: 0,
      lastActivity: DateTime.now(),
      inviteToken: _uuid.v4().substring(0, 6),
      members: const ['You'],
      expenses: const [],
    );

    state = [group, ...state];
    return group;
  }

  GroupModel? joinGroupFromInvite(String groupId, String token) {
    final index = state.indexWhere(
      (group) => group.id == groupId && group.inviteToken == token,
    );

    if (index == -1) {
      return null;
    }

    final group = state[index];
    if (group.members.contains('You')) {
      return group;
    }

    final updated = group.copyWith(
      members: [...group.members, 'You'],
      memberCount: group.memberCount + 1,
      lastActivity: DateTime.now(),
    );

    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) updated else state[i],
    ];
    return updated;
  }
}
