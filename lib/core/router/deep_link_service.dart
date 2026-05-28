import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stores a pending join link that arrived before auth completed.
final pendingJoinProvider = StateProvider<Uri?>((ref) => null);

class DeepLinkService {
  DeepLinkService(this._ref);

  final Ref _ref;
  StreamSubscription<Uri>? _sub;

  /// Call once from main() after ProviderScope is ready.
  Future<void> init() async {
    final appLinks = AppLinks();

    // Link that launched a cold start
    final initial = await appLinks.getInitialLink();
    if (initial != null) _handle(initial);

    // Links arriving while the app is running
    _sub = appLinks.uriLinkStream.listen(_handle);
  }

  void dispose() => _sub?.cancel();

  void _handle(Uri uri) {
    if (!_isJoinLink(uri)) return;
    _ref.read(pendingJoinProvider.notifier).state = uri;
  }

  static bool _isJoinLink(Uri uri) =>
      uri.pathSegments.length == 2 && uri.pathSegments[0] == 'join';

  /// Parse groupId and token out of a join URI.
  static ({String groupId, String token})? parseJoin(Uri uri) {
    if (!_isJoinLink(uri)) return null;
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return null;
    return (groupId: uri.pathSegments[1], token: token);
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(ref);
});
