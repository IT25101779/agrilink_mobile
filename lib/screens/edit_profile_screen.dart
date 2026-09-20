import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../localization/app_locale.dart';
import '../localization/chat_labels.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/profile_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../widgets/user_avatar.dart';

/// Change your name, phone, farm details, profile picture and password.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _saving = false;
  bool _photoBusy = false;
  int _photoVersion = 0;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _land = TextEditingController();
  final _company = TextEditingController();
  final _vehicle = TextEditingController();
  final _capacity = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  String? _district;
  String _soil = "unknown";
  String? _buyerType;

  static const _soils = ["loamy", "clay", "sandy", "silty", "peaty", "chalky", "unknown"];
  static const _buyerTypes = ["supermarket", "hotel", "exporter", "factory", "restaurant", "compost_hub"];

  String get _role => "${_user?["role"] ?? "farmer"}";

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _land, _company, _vehicle, _capacity, _currentPassword, _newPassword]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final result = await ProfileApi.me();
    if (!mounted) return;
    if (result["success"] == true) {
      final u = Map<String, dynamic>.from(result["data"] as Map);
      final farmer = (u["farmerProfile"] as Map?) ?? {};
      final buyer = (u["buyerProfile"] as Map?) ?? {};
      final driver = (u["driverProfile"] as Map?) ?? {};
      _name.text = "${u["fullName"] ?? ""}";
      _phone.text = "${u["phone"] ?? ""}";
      _district = kChatDistricts.contains(farmer["district"]) ? farmer["district"] as String : null;
      _land.text = farmer["landSizeAcres"] == null ? "" : "${farmer["landSizeAcres"]}";
      _soil = _soils.contains(farmer["soilType"]) ? farmer["soilType"] as String : "unknown";
      _company.text = "${buyer["companyName"] ?? ""}";
      _buyerType = _buyerTypes.contains(buyer["buyerType"]) ? buyer["buyerType"] as String : null;
      _vehicle.text = "${driver["vehicleRegistrationNo"] ?? ""}";
      _capacity.text = driver["vehicleCapacityKg"] == null ? "" : "${driver["vehicleCapacityKg"]}";
      setState(() {
        _user = u;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _snack("${result["message"] ?? ""}");
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _soilLabel(String s) {
    switch (s) {
      case "loamy":
        return tr("Loamy", "රොන්මඩ", "வளமான மண்");
      case "clay":
        return tr("Clay", "මැටි", "களிமண்");
      case "sandy":
        return tr("Sandy", "වැලි", "மணல்");
      case "silty":
        return tr("Silty", "රොන්", "வண்டல் மண்");
      case "peaty":
        return tr("Peaty", "පීට්", "கரிமண்");
      case "chalky":
        return tr("Chalky", "හුණුමය", "சுண்ணாம்பு மண்");
      default:
        return tr("Not sure", "නොදනී", "தெரியாது");
    }
  }

  String _buyerLabel(String s) {
    switch (s) {
      case "supermarket":
        return tr("Supermarket", "සුපිරි වෙළඳසැල", "பல்பொருள் அங்காடி");
      case "hotel":
        return tr("Hotel", "හෝටලය", "ஹோட்டல்");
      case "exporter":
        return tr("Exporter", "අපනයනකරු", "ஏற்றுமதியாளர்");
      case "factory":
        return tr("Factory", "කර්මාන්තශාලාව", "தொழிற்சாலை");
      case "restaurant":
        return tr("Restaurant", "ආපනශාලාව", "உணவகம்");
      default:
        return tr("Compost hub", "කොම්පෝස්ට් මධ්‍යස්ථානය", "உரம் மையம்");
    }
  }

  Future<void> _save() async {
    final fields = <String, dynamic>{"fullName": _name.text.trim(), "phone": _phone.text.trim()};
    if (_role == "farmer") {
      fields["farmerProfile"] = {
        if (_district != null) "district": _district,
        if (_land.text.trim().isNotEmpty) "landSizeAcres": double.tryParse(_land.text.trim()) ?? 0,
        "soilType": _soil,
      };
    } else if (_role == "buyer") {
      fields["buyerProfile"] = {"companyName": _company.text.trim(), if (_buyerType != null) "buyerType": _buyerType};
    } else if (_role == "driver") {
      fields["driverProfile"] = {"vehicleRegistrationNo": _vehicle.text.trim(), if (_capacity.text.trim().isNotEmpty) "vehicleCapacityKg": double.tryParse(_capacity.text.trim()) ?? 0};
    }
    setState(() => _saving = true);
    final result = await ProfileApi.update(fields);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result["success"] == true) {
      await AuthService.updateLocalProfile(name: _name.text.trim(), district: _district);
      _snack(tr("Profile updated.", "පැතිකඩ යාවත්කාලීන කළා.", "சுயவிவரம் புதுப்பிக்கப்பட்டது."));
      Navigator.pop(context, true);
    } else {
      _snack("${result["message"] ?? tr("Something went wrong.", "යම් දෙයක් වැරදුණා.", "ஏதோ தவறு நடந்துவிட்டது.")}");
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 512, imageQuality: 70);
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      setState(() => _photoBusy = true);
      final result = await ProfileApi.setAvatar(bytes);
      if (!mounted) return;
      setState(() {
        _photoBusy = false;
        if (result["success"] == true) _photoVersion++;
      });
      _snack(result["success"] == true ? tr("Photo updated.", "ඡායාරූපය යාවත්කාලීන කළා.", "புகைப்படம் புதுப்பிக்கப்பட்டது.") : "${result["message"] ?? ""}");
    } catch (_) {
      _snack(tr("Could not open the camera or gallery.", "කැමරාව හෝ ගැලරිය විවෘත කළ නොහැක.", "கேமரா அல்லது கேலரியைத் திறக்க முடியவில்லை."));
    }
  }

  void _photoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_rounded), title: Text(tr("Take a photo", "ඡායාරූපයක් ගන්න", "புகைப்படம் எடு")), onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.photo_library_rounded), title: Text(tr("Choose from gallery", "ගැලරියෙන් තෝරන්න", "கேலரியிலிருந்து தேர்ந்தெடு")), onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); }),
          if (_user?["avatarUpdatedAt"] != null || _photoVersion > 0)
            ListTile(leading: const Icon(Icons.delete_outline_rounded, color: Colors.red), title: Text(tr("Remove photo", "ඡායාරූපය ඉවත් කරන්න", "புகைப்படத்தை நீக்கு"), style: const TextStyle(color: Colors.red)), onTap: () async {
              Navigator.pop(context);
              await ProfileApi.removeAvatar();
              if (mounted) setState(() { _user?["avatarUpdatedAt"] = null; _photoVersion = 0; });
            }),
        ]),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_newPassword.text.length < 6) {
      _snack(tr("New password must be at least 6 characters.", "නව මුරපදය අවම වශයෙන් අක්ෂර 6ක් විය යුතුයි.", "புதிய கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்."));
      return;
    }
    final result = await ProfileApi.changePassword(_currentPassword.text, _newPassword.text);
    if (result["success"] == true) {
      _currentPassword.clear();
      _newPassword.clear();
    }
    _snack(result["success"] == true ? tr("Password changed.", "මුරපදය වෙනස් කළා.", "கடவுச்சொல் மாற்றப்பட்டது.") : "${result["message"] ?? ""}");
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.instance.t;
    return Scaffold(
      appBar: AppBar(title: Text(tr("Edit profile", "පැතිකඩ සංස්කරණය", "சுயவிவரத்தைத் திருத்து"))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _photoBusy ? null : _photoSheet,
                    child: Stack(
                      children: [
                        UserAvatar(key: ValueKey(_photoVersion), userId: _user?["_id"] as String?, name: _name.text, size: 96, hasPicture: _user?["avatarUpdatedAt"] != null || _photoVersion > 0, version: "${_user?["avatarUpdatedAt"]}$_photoVersion"),
                        Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(7), decoration: const BoxDecoration(color: AppColors.forest, shape: BoxShape.circle), child: _photoBusy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(controller: _name, decoration: InputDecoration(labelText: t("fullName"), prefixIcon: const Icon(Icons.person_rounded))),
                const SizedBox(height: 14),
                TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t("phoneNumber"), prefixIcon: const Icon(Icons.phone_rounded))),
                const SizedBox(height: 14),
                if (_role == "farmer") ...[
                  DropdownButtonFormField<String>(
                    value: _district,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t("district"), prefixIcon: const Icon(Icons.place_rounded)),
                    items: kChatDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _district = v),
                  ),
                  const SizedBox(height: 14),
                  TextField(controller: _land, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t("landSizeAcres"), prefixIcon: const Icon(Icons.landscape_rounded))),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _soil,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t("soilType"), prefixIcon: const Icon(Icons.grass_rounded)),
                    items: _soils.map((s) => DropdownMenuItem(value: s, child: Text(_soilLabel(s)))).toList(),
                    onChanged: (v) => setState(() => _soil = v ?? "unknown"),
                  ),
                ],
                if (_role == "buyer") ...[
                  TextField(controller: _company, decoration: InputDecoration(labelText: tr("Company name", "සමාගමේ නම", "நிறுவனப் பெயர்"), prefixIcon: const Icon(Icons.business_rounded))),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _buyerType,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: tr("Business type", "ව්‍යාපාර වර්ගය", "வணிக வகை")),
                    items: _buyerTypes.map((s) => DropdownMenuItem(value: s, child: Text(_buyerLabel(s)))).toList(),
                    onChanged: (v) => setState(() => _buyerType = v),
                  ),
                ],
                if (_role == "driver") ...[
                  TextField(controller: _vehicle, decoration: InputDecoration(labelText: t("vehicleRegNo"), prefixIcon: const Icon(Icons.local_shipping_rounded))),
                  const SizedBox(height: 14),
                  TextField(controller: _capacity, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t("vehicleCapacity"), prefixIcon: const Icon(Icons.scale_rounded))),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(t("saveChanges")),
                  ),
                ),
                const SizedBox(height: 30),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr("Change password", "මුරපදය වෙනස් කරන්න", "கடவுச்சொல்லை மாற்று"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextField(controller: _currentPassword, obscureText: true, decoration: InputDecoration(labelText: tr("Current password", "වත්මන් මුරපදය", "தற்போதைய கடவுச்சொல்"))),
                      const SizedBox(height: 12),
                      TextField(controller: _newPassword, obscureText: true, decoration: InputDecoration(labelText: t("newPassword"))),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _changePassword, child: Text(tr("Change password", "මුරපදය වෙනස් කරන්න", "கடவுச்சொல்லை மாற்று")))),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
