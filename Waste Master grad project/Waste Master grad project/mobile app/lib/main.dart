import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final userId = await AuthService.getUserId();
  
  runApp(MyApp(isLoggedIn: userId != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WasteMaster',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Apply Dark Design
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}
