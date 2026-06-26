import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/chat_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  static const _hints = [
    ('alex@finpilot.app',   'Overspender — dining, rideshare, danger'),
    ('jordan@finpilot.app', 'Saver — goals, net worth, healthy cash flow'),
    ('sam@finpilot.app',    'Stressed — overdue rent, overdraft risk'),
  ];

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final api  = ApiService();
    final data = await api.login(email, pass);

    if (!mounted) return;

    if (data == null) {
      setState(() { _loading = false; _error = 'Invalid email or password.'; });
      return;
    }

    final profileId = data['profile_id'] as String;
    await context.read<ChatProvider>().loadProfile(profileId);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),
              // Logo / wordmark
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: const Text('F', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                const Text('FinPilot', style: TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ]),
              const SizedBox(height: 12),
              const Text(
                'Your AI financial advisor.\nPersonalized to you.',
                style: TextStyle(color: AppColors.inkMid, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 48),

              // Email
              _label('Email'),
              const SizedBox(height: 6),
              _input(
                controller: _emailCtrl,
                hint: 'you@example.com',
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              _label('Password'),
              const SizedBox(height: 6),
              _input(
                controller: _passCtrl,
                hint: '••••••••',
                obscure: _obscure,
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: AppColors.inkLight),
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ],

              const SizedBox(height: 24),

              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 48),

              // Demo accounts hint
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEMO ACCOUNTS', style: TextStyle(color: AppColors.inkLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                    const SizedBox(height: 12),
                    ..._hints.map((h) => GestureDetector(
                      onTap: () {
                        _emailCtrl.text = h.$1;
                        _passCtrl.text = 'demo123';
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.$1, style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(h.$2, style: const TextStyle(color: AppColors.inkMid, fontSize: 11)),
                            ],
                          )),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.inkLight),
                        ]),
                      ),
                    )),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    const Text('Password: demo123', style: TextStyle(color: AppColors.inkLight, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w600),
      );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      onSubmitted: (_) => _submit(),
      style: const TextStyle(color: AppColors.ink, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inkLight),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix) : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.ink, width: 1.5)),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
