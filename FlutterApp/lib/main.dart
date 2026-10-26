import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/authentication/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dfejwzbblubfcxywcnhr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmZWp3emJibHViZmN4eXdjbmhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc3MzI2MDYsImV4cCI6MjEwMzMwODYwNn0.iTNReRAa8P7TcZRbjv0npW29Kk57SPVsX8r7XfuSLic',
  );
  runApp(const EasyRentalsApp());
}

class EasyRentalsApp extends StatelessWidget {
  const EasyRentalsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Easy Rentals', debugShowCheckedModeBanner: false, theme: AppTheme.lightTheme, home: const LoginScreen());
}
