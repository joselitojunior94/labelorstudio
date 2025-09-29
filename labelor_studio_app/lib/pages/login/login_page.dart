import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:labelor_studio_app/components/shell.dart';
import 'package:labelor_studio_app/service/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final u = TextEditingController();
  final p = TextEditingController();
  bool busy = false;
  String? err;

  Future<void> _login() async {
    setState(() => busy = true);
    err = null;
    try {
      final r = await http.post(
        Uri.parse('$kApiBaseUrl/api/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': u.text, 'password': p.text}),
      );
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body);
        final sp = await SharedPreferences.getInstance();
        await sp.setString('access', j['access']);
        await sp.setString('refresh', j['refresh']);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
      } else {
        err = 'Invalid credentials';
      }
    } catch (e) {
      err = '$e';
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _register() async {
    setState(() => busy = true);
    err = null;
    try {
      final r = await http.post(
        Uri.parse('$kApiBaseUrl/api/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': u.text, 'password': p.text}),
      );
      if (r.statusCode == 201) {
        await _login();
      } else {
        err = 'Registration failed: ${r.body}';
      }
    } catch (e) {
      err = '$e';
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Gradient(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [

                  Image.asset(
                    'assets/images/logo_without_background.png',
                     
                    fit: BoxFit.fill,
                  ),

          

                
                  TextField(controller: u, decoration: const InputDecoration(labelText: 'E-mail')),
                  const SizedBox(height: 8),
                  TextField(controller: p, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                  const SizedBox(height: 12),
                  if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: busy ? null : _login,
                        icon: const Icon(Icons.login),
                        label: const Text('To enter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : _register,
                        child: const Text('Register'),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Gradient extends StatelessWidget {
  const Gradient({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFEAF2FF), Color(0xFFF7FAFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: child,
    );
  }
}