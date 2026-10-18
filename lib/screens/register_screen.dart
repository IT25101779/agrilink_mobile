import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/smooth_route.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/language_toggle.dart';
import 'register_otp_screen.dart';
import '../widgets/district_picker_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _districtController = TextEditingController();
  final _referralController = TextEditingController();
  final _vehicleRegController = TextEditingController();
  final _vehicleCapacityController = TextEditingController();

  String _role = "farmer";
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _vehicleLicenseExpiry;

  Future<void> _pickVehicleLicenseExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _vehicleLicenseExpiry = picked);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == "driver" && _vehicleLicenseExpiry == null) {
      setState(() => _errorMessage = "Please choose the vehicle license expiry date.");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final farmerProfile = _role == "farmer" ? {"district": _districtController.text.trim()} : null;
    final driverProfile = _role == "driver"
        ? {
            "vehicleRegistrationNo": _vehicleRegController.text.trim(),
            "vehicleCapacityKg": double.tryParse(_vehicleCapacityController.text) ?? 0,
            "vehicleLicenseExpiryDate": _vehicleLicenseExpiry!.toIso8601String(),
          }
        : null;

    // Step 1 only validates and emails a code — nothing is created yet.
    final result = await AuthService.registerStart(
      fullName: _nameController.text.trim(),
      email: email,
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _role,
      referralCode: _referralController.text.trim(),
      farmerProfile: farmerProfile,
      driverProfile: driverProfile,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.push(
        context,
        SmoothRoute(
          page: RegisterOtpScreen(
            email: email,
            role: _role,
            registerArgs: {
              "fullName": _nameController.text.trim(),
              "email": email,
              "phone": _phoneController.text.trim(),
              "password": _passwordController.text,
              "role": _role,
              "farmerProfile": farmerProfile,
              "driverProfile": driverProfile,
              "referralCode": _referralController.text.trim(),
            },
          ),
        ),
      );
    } else {
      setState(() => _errorMessage = result["message"] ?? "Registration failed. Please try again.");
    }
  }

  Widget _roleChip(String value, String label, IconData icon) {
    final isSelected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.forest : AppColors.forestLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.forest, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.forest, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return Scaffold(
      appBar: AppBar(title: Text(t("createAccount")), actions: const [LanguageToggle()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeSlideIn(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t("iAmA"), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.inkMuted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roleChip("farmer", t("farmer"), Icons.agriculture),
                    const SizedBox(width: 10),
                    _roleChip("driver", t("truckDriver"), Icons.local_shipping),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: t("fullName"), prefixIcon: const Icon(Icons.person_outline, size: 20)),
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: t("email"), prefixIcon: const Icon(Icons.mail_outline, size: 20)),
                  validator: (v) => (v == null || !v.contains("@")) ? "Enter a valid email" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: t("phoneNumber"), prefixIcon: const Icon(Icons.phone_outlined, size: 20)),
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referralController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: "Invitation code (optional)", prefixIcon: Icon(Icons.card_giftcard_rounded, size: 20)),
                ),
                const SizedBox(height: 12),
                if (_role == "farmer")
                  DistrictPickerField(
                    controller: _districtController,
                    label: t("district"),
                    validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                  )
                else ...[
                  TextFormField(
                    controller: _vehicleRegController,
                    decoration: InputDecoration(labelText: t("vehicleRegNo"), prefixIcon: const Icon(Icons.badge_outlined, size: 20)),
                    validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleCapacityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: t("vehicleCapacity"), prefixIcon: const Icon(Icons.scale_outlined, size: 20)),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? "Enter a valid number" : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_rounded, size: 20),
                    title: const Text("Vehicle license expiry date", style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      _vehicleLicenseExpiry == null ? "Tap to choose" : "${_vehicleLicenseExpiry!.day}/${_vehicleLicenseExpiry!.month}/${_vehicleLicenseExpiry!.year}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickVehicleLicenseExpiry,
                  ),
                  Text(
                    "You'll also upload your driving license, vehicle license and vehicle photo for admin approval after this step.",
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t("passwordMin"), prefixIcon: const Icon(Icons.lock_outline, size: 20)),
                  validator: (v) => (v == null || v.length < 6) ? "At least 6 characters" : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(t("createAccount")),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
