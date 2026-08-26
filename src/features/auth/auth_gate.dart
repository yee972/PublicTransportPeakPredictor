import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_shell.dart';
import '../../widgets/state_views.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.checking:
        return const Scaffold(body: LoadingView(message: 'Starting up'));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const AppShell();
    }
  }
}
