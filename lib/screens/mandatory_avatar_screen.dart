import 'dart:convert';
import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../services/profile_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/help_widgets.dart';
import '../widgets/smooth_route.dart';
import 'driver_documents_screen.dart';
import 'home_screen.dart';

/// Shown right after a brand-new account is confirmed. A profile picture is
/// required for every role, so there is no skip button here — just a photo
/// picker and, once it's uploaded, the next step for that role.
class MandatoryAvatarScreen extends StatefulWidget {
  final String role;
  const MandatoryAvatarScreen({super.key, required this.role});

  @override
  State<MandatoryAvatarScreen> createState() => _MandatoryAvatarScreenState();
}

class _MandatoryAvatarScreenState extends State<MandatoryAvatarScreen> {
  bool _uploading = false;
  String? _preview; // base64, just for showing what was picked

  Future<void> _pick() async {
    final p = await askAndPickPhoto(context);
    if (p == null || !mounted) return;
    if (p == "TOO_BIG") return showSnack(context, tr("That photo is too large. Try again — it will be resized automatically.", "ඡායාරූපය විශාල වැඩියි. නැවත උත්සාහ කරන්න.", "படம் மிகப் பெரியது. மீண்டும் முயற்சிக்கவும்."));

    setState(() => _uploading = true);
    final r = await ProfileApi.setAvatar(base64Decode(p));
    setState(() => _uploading = false);
    if (!mounted) return;

    if (r["success"] == true) {
      setState(() => _preview = p);
      _continue();
    } else {
      showSnack(context, apiMessage(r));
    }
  }

  void _continue() {
    Navigator.pushAndRemoveUntil(
      context,
      SmoothRoute(page: widget.role == "driver" ? const DriverDocumentsScreen(firstTime: true) : const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tr("Add a profile picture", "පැතිකඩ රූපයක් එක් කරන්න", "சுயவிவரப் படத்தைச் சேர்க்கவும்")),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: AppColors.forestLight,
                    backgroundImage: _preview != null ? MemoryImage(base64Decode(_preview!)) : null,
                    child: _preview == null ? const Icon(Icons.person, size: 56, color: AppColors.forest) : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr(
                      "This is required to finish setting up your account — it helps other people trust who they are dealing with.",
                      "ගිණුම සම්පූර්ණ කිරීමට මෙය අවශ්‍ය වේ - අනෙක් පුද්ගලයින්ට විශ්වාසයක් ගොඩනඟා ගැනීමට එය උපකාරී වේ.",
                      "கணக்கை முடிக்க இது தேவை - மற்றவர்கள் நம்பிக்கை கொள்ள இது உதவும்.",
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _pick,
                      icon: const Icon(Icons.add_a_photo_rounded),
                      label: Text(_uploading ? tr("Uploading...", "උඩුගත කරමින්...", "பதிவேற்றுகிறது...") : tr("Take or choose a photo", "ඡායාරූපයක් ගන්න හෝ තෝරන්න", "படத்தை எடுக்கவும் அல்லது தேர்ந்தெடுக்கவும்")),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
