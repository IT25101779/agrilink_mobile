import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/smooth_route.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/language_toggle.dart';
import '../widgets/theme_toggle.dart';
import 'home_screen.dart';
import 'driver_home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result["success"] == true) {
      final role = await AuthService.getUserRole();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        SmoothRoute(page: role == "driver" ? const DriverHomeScreen() : const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = result["message"] ?? "Login failed. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.instance.t;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.forestDark, AppColors.forest],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [ThemeToggle(color: Colors.white), LanguageToggle()],
                  ),
                ),
              ),
              Expanded(
                child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  FadeSlideIn(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.eco_rounded, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t("appName"),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(t("signInToContinue"), style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delayMs: 120,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 12))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(labelText: t("email"), prefixIcon: const Icon(Icons.mail_outline, size: 20)),
                              validator: (v) => (v == null || !v.contains("@")) ? "Enter a valid email" : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: t("password"),
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? "Enter your password" : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context, SmoothRoute(page: const ForgotPasswordScreen())),
                                child: Text(t("forgotPassword")),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
                                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                              ),
                              const SizedBox(height: 10),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(t("login")),
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () => Navigator.push(context, SmoothRoute(page: const RegisterScreen())),
                              child: Text(t("dontHaveAccount")),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
