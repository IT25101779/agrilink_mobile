import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/help_widgets.dart';
import '../widgets/smooth_route.dart';
import 'driver_pending_screen.dart';

/// Mandatory for every driver: a photo of their driving license, a photo of
/// the vehicle's license (with its expiry date, since that has to be renewed
/// every year), and a photo of the vehicle itself. Submitting this is what
/// puts the account into "pending" for an admin to approve — there is no
/// skip button and no way to use the account's driver features without it.
class DriverDocumentsScreen extends StatefulWidget {
  /// true right after registration (no back button, routes to the pending screen on success);
  /// false when a rejected driver is resubmitting from DriverPendingScreen (has a back/cancel route).
  final bool firstTime;
  const DriverDocumentsScreen({super.key, this.firstTime = false});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  String? _license, _vehicleLicense, _vehicle;
  DateTime? _expiry;
  bool _submitting = false;

  Future<void> _pick(String which) async {
    final p = await askAndPickPhoto(context);
    if (p == null || !mounted) return;
    if (p == "TOO_BIG") return showSnack(context, tr("That photo is too large.", "ඡායාරූපය විශාල වැඩියි.", "படம் மிகப் பெரியது."));
    setState(() {
      if (which == "license") _license = p;
      if (which == "vehicleLicense") _vehicleLicense = p;
      if (which == "vehicle") _vehicle = p;
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  bool get _ready => _license != null && _vehicleLicense != null && _vehicle != null && _expiry != null;

  Future<void> _submit() async {
    if (!_ready) {
      showSnack(context, tr("Please add all three photos and the license expiry date.", "ඡායාරූප තුනම සහ බලපත්‍රයේ කල් ඉකුත් වන දිනය එක් කරන්න.", "மூன்று படங்களையும் உரிமத் தேதியையும் சேர்க்கவும்."));
      return;
    }
    setState(() => _submitting = true);
    final r = await HelpApi.submitDriverVerification(
      licenseBase64: _license!,
      vehicleLicenseBase64: _vehicleLicense!,
      vehicleBase64: _vehicle!,
      vehicleLicenseExpiryDate: _expiry!,
    );
    setState(() => _submitting = false);
    if (!mounted) return;

    if (r["success"] == true) {
      if (widget.firstTime) {
        Navigator.pushAndRemoveUntil(context, SmoothRoute(page: const DriverPendingScreen()), (route) => false);
      } else {
        showSnack(context, apiMessage(r, tr("Documents submitted.", "ලේඛන යවන ලදි.", "ஆவணங்கள் அனுப்பப்பட்டன.")));
        Navigator.of(context).pop(true);
      }
    } else {
      showSnack(context, apiMessage(r));
    }
  }

  Widget _photoTile(String label, String? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.forestLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: value != null ? AppColors.forest : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(value != null ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: AppColors.forest, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tr("Vehicle & license documents", "වාහන හා බලපත්‍ර ලේඛන", "வாகனம் & உரிம ஆவணங்கள்")),
            automaticallyImplyLeading: !widget.firstTime,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    "An admin reviews these before your driver account can be used. This only needs doing once a year, when your vehicle license is renewed.",
                    "ඔබගේ රියදුරු ගිණුම භාවිතා කිරීමට පෙර පරිපාලක මෙය පරීක්ෂා කරයි. වාහන බලපත්‍රය අලුත් කරන විට වසරකට වරක් මෙය කරන්න.",
                    "உங்கள் ஓட்டுநர் கணக்கைப் பயன்படுத்தும் முன் நிர்வாகி இதைச் சரிபார்ப்பார். வாகன உரிமம் புதுப்பிக்கப்படும்போது ஆண்டுக்கு ஒரு முறை இது தேவை.",
                  ),
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _photoTile(tr("Driving license", "රියදුරු බලපත්‍රය", "ஓட்டுநர் உரிமம்"), _license, () => _pick("license"))),
                    const SizedBox(width: 10),
                    Expanded(child: _photoTile(tr("Vehicle license", "වාහන බලපත්‍රය", "வாகன உரிமம்"), _vehicleLicense, () => _pick("vehicleLicense"))),
                    const SizedBox(width: 10),
                    Expanded(child: _photoTile(tr("Vehicle photo", "වාහනයේ ඡායාරූපය", "வாகனப் படம்"), _vehicle, () => _pick("vehicle"))),
                  ],
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded, color: AppColors.forest),
                  title: Text(tr("Vehicle license expiry date", "වාහන බලපත්‍රයේ කල් ඉකුත් වන දිනය", "வாகன உரிம காலாவதி தேதி")),
                  subtitle: Text(_expiry == null ? tr("Tap to choose", "තෝරන්න ස්පර්ශ කරන්න", "தேர்வு செய்ய தட்டவும்") : "${_expiry!.day}/${_expiry!.month}/${_expiry!.year}"),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickExpiry,
                  tileColor: AppColors.forestLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(tr("Submit for approval", "අනුමැතියට යවන්න", "ஒப்புதலுக்கு அனுப்பு")),
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
