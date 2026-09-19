import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small shared building blocks used by the newer screens (Group Lots,
/// Buyer Requests, Farm Passport, price forecast, listing cards). They read
/// the current light/dark theme, so nothing here needs its own dark-mode code.

bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

Color surfaceOf(BuildContext context) => isDarkMode(context) ? AppColorsDark.surface : AppColors.surface;
Color borderOf(BuildContext context) => isDarkMode(context) ? AppColorsDark.border : AppColors.border;
Color inkOf(BuildContext context) => isDarkMode(context) ? AppColorsDark.ink : AppColors.ink;
Color mutedOf(BuildContext context) => isDarkMode(context) ? AppColorsDark.inkMuted : AppColors.inkMuted;

/// A soft background tint of an accent colour — works on light AND dark.
Color tintOf(BuildContext context, Color accent) => accent.withOpacity(isDarkMode(context) ? 0.20 : 0.10);

/// 12500 -> "LKR 12,500"
String lkr(num value) => "LKR ${groupedNumber(value)}";

/// 12500 -> "12,500"
String groupedNumber(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(",");
    buffer.write(digits[i]);
  }
  return value < 0 ? "-$buffer" : buffer.toString();
}

/// 350 -> "350", 110.6 -> "110.6"
String priceText(num value) {
  final d = value.toDouble();
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

/// Reads a JSON number that may arrive as int or double.
double numOf(dynamic value, [double fallback = 0]) => value is num ? value.toDouble() : fallback;

/// A small rounded label, e.g. "Live", "Flash sale", "Expired".
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: tintOf(context, color), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// A rounded card with the app's border and surface colours.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? background;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: background ?? surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderOf(context)),
    );
    final content = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: decoration,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: content),
            ),
    );
  }
}

/// A title with an optional one-line explanation underneath.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: TextStyle(fontSize: 12.5, color: mutedOf(context), height: 1.35)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A tinted hint / explanation box with an icon.
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const InfoBanner({super.key, required this.icon, required this.text, this.color = AppColors.forest});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tintOf(context, color), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.4, color: inkOf(context)))),
        ],
      ),
    );
  }
}

/// A slim rounded progress bar (value 0.0 - 1.0).
class RoundedBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const RoundedBar({super.key, required this.value, required this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: tintOf(context, color),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// "Closes in 3 days" / "Closes today" / "Closed"
String closesInText(String? isoDate, {required bool si}) {
  if (isoDate == null) return "";
  final date = DateTime.tryParse(isoDate);
  if (date == null) return "";
  final hours = date.difference(DateTime.now()).inHours;
  if (hours <= 0) return si ? "වසා ඇත" : "Closed";
  final days = (hours / 24).ceil();
  if (days <= 1) return si ? "අද වසයි" : "Closes today";
  return si ? "දින $days කින් වසයි" : "Closes in $days days";
}
