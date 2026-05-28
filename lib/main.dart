import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/router/deep_link_service.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  await initNotifications();
  await requestPermission();
  runApp(const ProviderScope(child: SettleApp()));
}

class SettleApp extends ConsumerStatefulWidget {
  const SettleApp({super.key});

  @override
  ConsumerState<SettleApp> createState() => _SettleAppState();
}

class _SettleAppState extends ConsumerState<SettleApp> {
  @override
  void initState() {
    super.initState();
    // Init after first frame so ProviderScope is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deepLinkServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Settle',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
