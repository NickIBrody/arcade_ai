import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'ui/chat/chat_screen.dart';
import 'ui/onboarding/welcome_screen.dart';
import 'ui/settings/lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
  ));
  final state = AppState();
  await state.init();
  runApp(ArcadeApp(state: state));
}

class ArcadeApp extends StatelessWidget {
  final AppState state;
  const ArcadeApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        title: 'Arcade AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.locked) return const LockScreen();
    if (!app.settings.onboarded) return const WelcomeScreen();
    return const ChatScreen();
  }
}
