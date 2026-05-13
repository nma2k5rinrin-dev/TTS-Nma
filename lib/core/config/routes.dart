import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../../features/auth/logic/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/tts/presentation/tts_page.dart';
import '../../features/voice_clone/presentation/voice_clone_page.dart';
import '../../features/stt/presentation/stt_page.dart';
import '../../features/credits/presentation/credits_page.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';
import '../../features/account/presentation/account_dashboard_page.dart';
import '../../features/history/presentation/history_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/login':
        return _page(const LoginPage(), settings);
      case '/register':
        return _page(const RegisterPage(), settings);
      case '/home':
        return _page(const AuthGuard(child: HomePage()), settings);
      case '/tts':
        return _page(const AuthGuard(child: TtsPage()), settings);
      case '/voice-clone':
        return _page(const AuthGuard(child: VoiceClonePage()), settings);
      case '/stt':
        return _page(const AuthGuard(child: SttPage()), settings);
      case '/credits':
        return _page(const AuthGuard(child: CreditsPage()), settings);
      case '/account':
        return _page(const AuthGuard(child: AccountDashboardPage()), settings);
      case '/admin':
        return _page(
          const SuperAdminGuard(child: AdminDashboardPage()),
          settings,
        );
      case '/history':
        final service = settings.arguments as String? ?? 'tts';
        return _page(AuthGuard(child: HistoryPage(service: service)), settings);
      default:
        return _page(
          Scaffold(body: Center(child: Text('Not found: ${settings.name}'))),
          settings,
        );
    }
  }

  static MaterialPageRoute _page(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

class AuthGuard extends ConsumerWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return profile.when(
      data: (p) {
        if (p != null) return child;
        if (SupabaseService.isAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const LoginPage();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _AuthErrorPage(error: error),
    );
  }
}

class SuperAdminGuard extends ConsumerWidget {
  final Widget child;
  const SuperAdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return profile.when(
      data: (p) {
        if (p == null && SupabaseService.isAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (p == null) return const LoginPage();
        if (p.isSuperAdmin) return child;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(title: const Text('Admin Panel')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Ban khong co quyen vao Admin Panel.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (_) => false),
                    child: const Text('Ve trang chu'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _AuthErrorPage(error: error),
    );
  }
}

class _AuthErrorPage extends ConsumerWidget {
  final Object error;
  const _AuthErrorPage({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44),
              const SizedBox(height: 12),
              Text(
                'Không tải được phiên đăng nhập.\n$error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(userProfileProvider.notifier).refreshProfile(),
                child: const Text('Thử lại'),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(userProfileProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (_) => false);
                  }
                },
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
