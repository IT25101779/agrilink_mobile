import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/smooth_route.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/language_toggle.dart';
import 'home_screen.dart';
import 'driver_home_screen.dart';

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
  final _vehicleRegController = TextEditingController();
  final _vehicleCapacityController = TextEditingController();

  String _role = "farmer";
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _role,
      farmerProfile: _role == "farmer" ? {"district": _districtController.text.trim()} : null,
      driverProfile: _role == "driver"
          ? {
              "vehicleRegistrationNo": _vehicleRegController.text.trim(),
              "vehicleCapacityKg": double.tryParse(_vehicleCapacityController.text) ?? 0,
            }
          : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        SmoothRoute(page: _role == "driver" ? const DriverHomeScreen() : const HomeScreen()),
        (route) => false,
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
                if (_role == "farmer")
                  TextFormField(
                    controller: _districtController,
                    decoration: InputDecoration(labelText: t("district"), prefixIcon: const Icon(Icons.location_on_outlined, size: 20)),
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
