import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth/brand_splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SportyQoApp());
}

class SportyQoApp extends StatelessWidget {
  const SportyQoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportyQo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const BrandSplashScreen(),
    );
  }
}