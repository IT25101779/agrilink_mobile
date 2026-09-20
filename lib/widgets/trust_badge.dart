import 'package:flutter/material.dart';
import '../localization/tr.dart';

/// "⭐ 4.8 · Trusted" — built from the trust summary the server sends for a person.
class TrustBadge extends StatelessWidget {
  final Map<dynamic, dynamic>? trust;
  final bool compact;
  const TrustBadge({super.key, required this.trust, this.compact = false});

  static String label(String badge) {
    switch (badge) {
      case "top":
        return tr("Top rated", "ඉහළම ශ්‍රේණිගත", "சிறந்த மதிப்பீடு");
      case "trusted":
        return tr("Trusted", "විශ්වාසවන්ත", "நம்பகமானவர்");
      case "rising":
        return tr("Rising", "නැගී එන", "வளர்ந்து வருபவர்");
      default:
        return tr("New", "අලුත්", "புதியவர்");
    }
  }

  static Color colorFor(String badge) {
    switch (badge) {
      case "top":
        return const Color(0xFFB45309);
      case "trusted":
        return const Color(0xFF15803D);
      case "rising":
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (trust == null) return const SizedBox.shrink();
    final badge = "${trust!["badge"] ?? "new"}";
    final color = colorFor(badge);
    final count = (trust!["ratingCount"] as num?)?.toInt() ?? 0;
    final average = (trust!["average"] as num?)?.toDouble() ?? 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge == "new" ? Icons.fiber_new_rounded : Icons.verified_rounded, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(count > 0 ? "${average.toStringAsFixed(1)} ★ · ${label(badge)}" : label(badge), style: TextStyle(fontSize: compact ? 10.5 : 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
