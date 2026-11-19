import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..load(),
      child: const AuctionApp(),
    ),
  );
}

class AuctionApp extends StatelessWidget {
  const AuctionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Public Asset Auction',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Consumer<AuthProvider>(
        builder: (_, auth, _) {
          if (auth.loading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return auth.isLoggedIn ? const HomeShell() : const LoginScreen();
        },
      ),
    );
  }
}