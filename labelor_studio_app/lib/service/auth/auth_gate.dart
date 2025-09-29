import 'package:flutter/material.dart';
import 'package:labelor_studio_app/components/shell.dart';
import 'package:labelor_studio_app/pages/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _hasToken;
  @override
  void initState() {
    super.initState();
    _hasToken = _check();
  }

  Future<bool> _check() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('access') != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken,
      builder: (_, s) {
        if (!s.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return s.data! ? const Shell() : const LoginPage();
      },
    );
  }
}