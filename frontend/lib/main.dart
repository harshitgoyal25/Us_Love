import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/auth_provider.dart';
import 'models/room_model.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/games/custom_quiz_screen.dart';
import 'screens/games/dots_and_boxes_screen.dart';
import 'screens/games/co_draw_screen.dart';
import 'screens/games/photobooth_screen.dart';
import 'core/app_theme.dart';
import 'core/error_service.dart';
import 'widgets/premium_error_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.loadFromStorage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: ErrorService.instance),
      ],
      child: const MyApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!auth.isLoggedIn && !isAuthRoute) return '/login';
    if (auth.isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/lobby',
      builder: (context, state) {
        final room = state.extra as RoomModel?;
        if (room == null) return const HomeScreen();
        return LobbyScreen(room: room);
      },
    ),
    GoRoute(
      path: '/game/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        if (gameId == 'custom_quiz') {
          final room = state.extra as RoomModel?;
          if (room != null) {
            return CustomQuizScreen(room: room);
          }
        } else if (gameId == 'dots_and_boxes') {
          final room = state.extra as RoomModel?;
          if (room != null) {
            return DotsAndBoxesScreen(room: room);
          }
        } else if (gameId == 'co_draw') {
          final room = state.extra as RoomModel?;
          if (room != null) {
            return CoDrawScreen(room: room);
          }
        } else if (gameId == 'photobooth') {
          final room = state.extra as RoomModel?;
          if (room != null) {
            return PhotoboothScreen(room: room);
          }
        }
        return GamePlaceholderScreen(gameId: gameId);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Love',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.bg1,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.rose,
          secondary: AppTheme.gold,
          surface: AppTheme.bg3,
          background: AppTheme.bg1,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Consumer<ErrorService>(
              builder: (context, errorService, _) {
                final error = errorService.currentError;
                if (error == null) return const SizedBox.shrink();
                return PremiumErrorDialog(
                  error: error,
                  onDismiss: () => errorService.clearError(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Placeholder screen for games — wrapped in the new theme
class GamePlaceholderScreen extends StatelessWidget {
  final String gameId;
  const GamePlaceholderScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingHeartsBackground(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: AppTheme.velvetCard(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎮', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 24),
                Text(
                  gameId.replaceAll('_', ' ').toUpperCase(),
                  style: AppTheme.display(24),
                ),
                const SizedBox(height: 12),
                Text(
                  'Coming soon!',
                  style: AppTheme.body(16, color: AppTheme.rose),
                ),
                const SizedBox(height: 32),
                AppTheme.roseButton(
                  label: 'Leave Game',
                  onTap: () => context.go('/home'),
                  outlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
