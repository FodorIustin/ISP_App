import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'screens/access_code_screen.dart';
import 'screens/change_language_screen.dart';
import 'screens/language_screen.dart';
import 'screens/lesson_complete_screen.dart';
import 'screens/lesson_detail_screen.dart';
import 'screens/lesson_questions_screen.dart';
import 'screens/lesson_results_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_auth_screen.dart';
import 'screens/register_profile_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/main_shell.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/access-code',
      builder: (context, state) => const AccessCodeScreen(),
    ),
    GoRoute(
      path: '/register-auth',
      builder: (context, state) => const RegisterAuthScreen(),
    ),
    GoRoute(
      path: '/register-profile',
      builder: (context, state) => const RegisterProfileScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/change-language',
      builder: (context, state) => const ChangeLanguageScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: '/lesson/:lessonId',
      builder: (context, state) => LessonDetailScreen(
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
    GoRoute(
      path: '/lesson-complete/:lessonId',
      builder: (context, state) => LessonCompleteScreen(
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
    GoRoute(
      path: '/lesson-questions/:lessonId',
      builder: (context, state) => LessonQuestionsScreen(
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
    GoRoute(
      path: '/lesson-results/:lessonId',
      builder: (context, state) => LessonResultsScreen(
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize(
    clientId: '30164116362-7dru1hifp7gqkeoisecca55jnefersip.apps.googleusercontent.com',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
