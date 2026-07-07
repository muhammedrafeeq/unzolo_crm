import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';
import 'core/app_routes.dart';
import 'core/utils/pointer_lock.dart';
import 'core/state/unzolo_state.dart' show authProvider, preloadOfflineAuth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  lockCanvasPointers();
  Future.delayed(const Duration(milliseconds: 1500), () {
    unlockCanvasPointers();
  });
  await Supabase.initialize(
    url: 'https://csnwknyuvynkndsqqeso.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNzbndrbnl1dnlua25kc3FxZXNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0MDA0NTUsImV4cCI6MjA5ODk3NjQ1NX0.Tx9eqXeCcWbj7K6s6moQXu4dxtiC1rGJKaJFw6h93Io',
  );
  await preloadOfflineAuth();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class PointerLockNavigatorObserver extends NavigatorObserver {
  void _lock() {
    lockCanvasPointers();
    Future.delayed(const Duration(milliseconds: 350), () {
      unlockCanvasPointers();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _lock();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _lock();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _lock();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _lock();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return ScreenUtilInit(
      // Design baseline: 375×812 (iPhone 11 logical pixels)
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) {
        return MaterialApp(
          title: 'Unzolo CRM',
          debugShowCheckedModeBanner: false,
          // Theme is created inside builder so .sp/.w/.h are available
          theme: AppTheme.lightTheme,
          initialRoute: authState.isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
          navigatorObservers: [PointerLockNavigatorObserver()],
          onGenerateRoute: (settings) {
            final builder = AppRoutes.routes[settings.name];
            if (builder == null) return null;
            return MaterialPageRoute(builder: builder, settings: settings);
          },
        );
      },
    );
  }
}
