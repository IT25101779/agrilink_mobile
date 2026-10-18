import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../widgets/smooth_route.dart';
import 'mandatory_avatar_screen.dart';

/// Step 2 of registration: confirm the 6-digit code emailed to the person,
/// which actually creates the account (nothing exists yet until this succeeds).
/// Every new account — farmer or driver — passes through here before anything else,
/// so a fake email address can never finish signing up.
class RegisterOtpScreen extends StatefulWidget {
  final String email;
  final String role;
  final Map<String, dynamic> registerArgs;

  const RegisterOtpScreen({super.key, required this.email, required this.role, required this.registerArgs});

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _resending = false;
  String? _message;
  bool _isError = false;

  Future<void> _verify() async {
    if (_otpController.text.trim().length != 6) {
      setState(() {
        _message = "Enter the 6-digit code.";
        _isError = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await AuthService.registerVerify(email: widget.email, otp: _otpController.text.trim());

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result["success"] == true) {
      // Every account — farmer or driver — must add a profile picture next;
      // a driver then continues on to the mandatory document screens.
      Navigator.pushAndRemoveUntil(
        context,
        SmoothRoute(page: MandatoryAvatarScreen(role: widget.role)),
        (route) => false,
      );
    } else {
      setState(() {
        _isError = true;
        _message = result["message"] ?? "Could not verify that code.";
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _message = null;
    });
    final result = await AuthService.registerStart(
      fullName: widget.registerArgs["fullName"],
      email: widget.registerArgs["email"],
      phone: widget.registerArgs["phone"],
      password: widget.registerArgs["password"],
      role: widget.registerArgs["role"],
      farmerProfile: widget.registerArgs["farmerProfile"],
      driverProfile: widget.registerArgs["driverProfile"],
      referralCode: widget.registerArgs["referralCode"] ?? "",
    );
    setState(() {
      _resending = false;
      _isError = result["success"] != true;
      _message = result["message"] ?? (result["success"] == true ? "Code resent." : "Something went wrong.");
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(tr("Confirm your email", "ඔබේ විද්‍යුත් තැපෑල තහවුරු කරන්න", "உங்கள் மின்னஞ்சலை உறுதிப்படுத்தவும்"))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr("Enter the code we sent you", "අපි යැවූ කේතය ඇතුළත් කරන්න", "நாங்கள் அனுப்பிய குறியீட்டை உள்ளிடவும்"),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "${tr("We emailed a 6-digit code to", "අපි 6-ඉලක්කම් කේතයක් විද්‍යුත් තැපෑලෙන් යැවුවා", "6-இலக்க குறியீட்டை மின்னஞ்சல் செய்தோம்")} ${widget.email}. ${tr("It expires in 1 hour.", "එය පැය 1කින් කල් ඉකුත් වේ.", "இது 1 மணி நேரத்தில் காலாவதியாகும்.")}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(labelText: tr("6-digit code", "ඉලක්කම් 6 කේතය", "6-இலக்க குறியீடு"), border: const OutlineInputBorder()),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: TextStyle(color: _isError ? Colors.red : Colors.green[700], fontSize: 13)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verify,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(tr("Confirm & create account", "තහවුරු කර ගිණුම සාදන්න", "உறுதிசெய்து கணக்கை உருவாக்கவும்")),
                  ),
                ),
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? tr("Sending...", "යවමින්...", "அனுப்புகிறது...") : tr("Resend code", "කේතය නැවත යවන්න", "குறியீட்டை மீண்டும் அனுப்பு")),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
