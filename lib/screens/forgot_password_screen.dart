import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../localization/app_locale.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  Future<void> _requestCode() async {
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains("@")) {
      setState(() {
        _message = "Enter a valid email.";
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await AuthService.forgotPassword(_emailController.text.trim());

    setState(() {
      _isLoading = false;
      _isError = result["success"] != true;
      _message = result["message"] ?? "Something went wrong.";
      if (result["success"] == true) _codeSent = true;
    });
  }

  Future<void> _resetPassword() async {
    if (_otpController.text.trim().isEmpty || _newPasswordController.text.length < 6) {
      setState(() {
        _message = "Enter the 6-digit code and a password with at least 6 characters.";
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await AuthService.resetPassword(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    setState(() {
      _isLoading = false;
      _isError = result["success"] != true;
      _message = result["message"] ?? "Something went wrong.";
    });

    if (result["success"] == true && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return Scaffold(
      appBar: AppBar(
        title: Text(t("resetPassword")),
              ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _codeSent ? "Enter the code we sent you" : "Forgot your password?",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? "We emailed a 6-digit code to ${_emailController.text.trim()}. It expires in 15 minutes."
                  : "Enter your email and we'll send you a code to reset your password.",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t("email"), border: const OutlineInputBorder()),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: t("sixDigitCode"), border: const OutlineInputBorder()),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: t("newPassword"), border: const OutlineInputBorder()),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(_message!, style: TextStyle(color: _isError ? Colors.red : Colors.green[700], fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_codeSent ? _resetPassword : _requestCode),
                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_codeSent ? t("resetPassword") : t("sendResetCode")),
              ),
            ),
            if (_codeSent)
              TextButton(
                onPressed: _isLoading ? null : _requestCode,
                child: const Text("Resend code"),
              ),
          ],
        ),
      ),
    );
      },
    );
  }
}
