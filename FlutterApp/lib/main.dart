import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/authentication/login_screen.dart';

/// Application entry point.
///
/// Initialises Supabase before running the app, then boots [EasyRentalsApp]
/// with the login screen as the initial route.
///
/// Note: the Supabase URL and anon key are hard-coded here. The anon key is
/// designed to be public (access is enforced by Row Level Security), but for
/// production it's still preferable to inject these via build-time
/// configuration (e.g. `--dart-define`) rather than committing them.
Future<void> main() async {
  // Required before any plugin (here: Supabase's auth/storage) is used from
  // the Flutter engine during startup.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the global Supabase client. After this call,
  // `Supabase.instance.client` is available everywhere in the app (used by
  // the view models and screens).
  await Supabase.initialize(
    url: 'https://dfejwzbblubfcxywcnhr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmZWp3emJibHViZmN4eXdjbmhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc3MzI2MDYsImV4cCI6MjEwMzMwODYwNn0.iTNReRAa8P7TcZRbjv0npW29Kk57SPVsX8r7XfuSLic',
  );

  // Launch the app once Supabase is ready.
  runApp(const EasyRentalsApp());
}

/// Root widget for Easy Rentals.
///
/// Configures the [MaterialApp] title, debug banner, and global theme, and
/// starts the user at [LoginScreen]. Authenticated navigation is then handled
/// by [MainShell] (see `Views/dashboard/main_shell.dart`).
class EasyRentalsApp extends StatelessWidget {
  const EasyRentalsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        // Window title (shown in OS task switchers on some platforms).
        title: 'Easy Rentals',
        // Hide the debug banner in all builds, including dev.
        debugShowCheckedModeBanner: false,
        // App-wide theme (colours, typography, button/input styling).
        theme: AppTheme.lightTheme,
        // First screen shown on launch; the user signs in from here.
        home: const LoginScreen(),
      );
}