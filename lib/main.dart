import 'package:flutter/material.dart';
import 'api/parent_api.dart';
import 'api/session_store.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ParentApp());
}

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "School Transport",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const _StartupGate(),
    );
  }
}

/// Checks for a remembered (student_code, phone) on launch and skips
/// straight to the home screen if it's still valid; otherwise falls back
/// to the login screen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final saved = await SessionStore.load();
    if (saved == null) {
      _goToLogin();
      return;
    }
    final (code, phone) = saved;
    try {
      final summary = await ParentApi(studentCode: code, phone: phone).login();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(studentCode: code, phone: phone, initialSummary: summary),
        ),
      );
    } catch (_) {
      // Saved details no longer match (e.g. phone changed on file) —
      // fall back to a normal login instead of getting stuck.
      await SessionStore.clear();
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
