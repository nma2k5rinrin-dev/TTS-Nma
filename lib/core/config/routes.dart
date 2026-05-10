import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/logic/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/tts/presentation/tts_page.dart';
import '../../features/voice_clone/presentation/voice_clone_page.dart';
import '../../features/stt/presentation/stt_page.dart';
import '../../features/credits/presentation/credits_page.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';
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
        return _page(const HomePage(), settings);
      case '/tts':
        return _page(const TtsPage(), settings);
      case '/voice-clone':
        return _page(const VoiceClonePage(), settings);
      case '/stt':
        return _page(const SttPage(), settings);
      case '/credits':
        return _page(const CreditsPage(), settings);
      case '/admin':
        return _page(const AdminDashboardPage(), settings);
      case '/history':
        final service = settings.arguments as String? ?? 'tts';
        return _page(HistoryPage(service: service), settings);
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
      data: (p) => p == null ? const LoginPage() : child,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LoginPage(),
    );
  }
}
