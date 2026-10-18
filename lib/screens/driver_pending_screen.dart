import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/smooth_route.dart';
import 'driver_documents_screen.dart';
import 'driver_home_screen.dart';
import 'login_screen.dart';

/// Shown instead of the driver home screen whenever a driver's account
/// isn't approved yet (just submitted, still pending, or rejected).
/// Checks the server for the current status so it reflects what the
/// admin has actually decided, not just what the app last saw.
class DriverPendingScreen extends StatefulWidget {
  const DriverPendingScreen({super.key});

  @override
  State<DriverPendingScreen> createState() => _DriverPendingScreenState();
}

class _DriverPendingScreenState extends State<DriverPendingScreen> {
  bool _loading = true;
  String _status = "pending";
  String _note = "";

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    final r = await HelpApi.driverVerificationStatus();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true && r["data"] is Map) {
        _status = "${(r["data"] as Map)["status"] ?? "pending"}";
        _note = "${(r["data"] as Map)["note"] ?? ""}";
      }
    });
    if (_status == "verified" && mounted) {
      Navigator.pushAndRemoveUntil(context, SmoothRoute(page: const DriverHomeScreen()), (route) => false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, SmoothRoute(page: const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final rejected = _status == "rejected";
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tr("Account approval", "ගිණුම් අනුමැතිය", "கணக்கு ஒப்புதல்")),
            automaticallyImplyLeading: false,
            actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout)],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _check,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 30),
                      Icon(
                        rejected ? Icons.error_outline_rounded : Icons.hourglass_top_rounded,
                        size: 64,
                        color: rejected ? AppColors.danger : AppColors.forest,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        rejected
                            ? tr("Application not approved", "අයදුම්පත අනුමත කර නැත", "விண்ணப்பம் ஏற்கப்படவில்லை")
                            : tr("Waiting for admin approval", "පරිපාලක අනුමැතිය සඳහා රැඳී සිටී", "நிர்வாகி ஒப்புதலுக்காக காத்திருக்கிறது"),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rejected
                            ? (_note.isNotEmpty
                                ? _note
                                : tr("Please check your documents and submit them again.", "ඔබේ ලේඛන පරීක්ෂා කර නැවත යවන්න.", "உங்கள் ஆவணங்களை சரிபார்த்து மீண்டும் அனுப்பவும்."))
                            : tr(
                                "An admin is checking your driving license, vehicle license and vehicle photo. You'll be able to use the app as a driver as soon as they approve it.",
                                "ඔබේ රියදුරු බලපත්‍රය, වාහන බලපත්‍රය සහ වාහනයේ ඡායාරූපය පරිපාලක පරීක්ෂා කරමින් සිටී. අනුමත වූ විගස ඔබට රියදුරෙකු ලෙස යෙදුම භාවිත කළ හැක.",
                                "உங்கள் ஓட்டுநர் உரிமம், வாகன உரிமம் மற்றும் வாகனப் படத்தை நிர்வாகி சரிபார்க்கிறார். ஒப்புதல் கிடைத்ததும் ஓட்டுநராக பயன்பாட்டைப் பயன்படுத்தலாம்.",
                              ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 30),
                      if (rejected)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final done = await Navigator.push<bool>(context, SmoothRoute(page: const DriverDocumentsScreen()));
                              if (done == true) _check();
                            },
                            child: Text(tr("Resubmit documents", "ලේඛන නැවත යවන්න", "ஆவணங்களை மீண்டும் அனுப்பு")),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _check,
                            child: Text(tr("Check again", "නැවත පරීක්ෂා කරන්න", "மீண்டும் சரிபார்க்கவும்")),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
