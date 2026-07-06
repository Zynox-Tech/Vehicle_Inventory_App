import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'customer';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthService>();
    final err = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role,
    );
    if (err != null) {
      setState(() { _error = err; });
    } else {
      if (mounted) Navigator.pop(context);
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appName = 'Vehicle Parts Inventory';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // App name header
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 24.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/splash.png',
                    height: 200,
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                    validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
                  ),
                  const SizedBox(height: 16),
                  const Text('Select role'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'customer',
                        groupValue: _role,
                        onChanged: (v) => setState(() => _role = v ?? 'customer'),
                      ),
                      const Text('Customer'),
                      const SizedBox(width: 12),
                      // Radio<String>(
                      //   value: 'staff',
                      //   groupValue: _role,
                      //   onChanged: (v) => setState(() => _role = v ?? 'customer'),
                      // ),
                      // const Text('Staff'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Register'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
