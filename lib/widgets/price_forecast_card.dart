import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../localization/tr.dart';
import '../services/insights_api.dart';
import '../theme/app_theme.dart';
import 'shimmer_loading.dart';
import 'ui_kit.dart';

/// Shows the 12-week price outlook for a crop as a small chart, plus the
/// reasons behind it (festival demand, supply, weather, disease outbreaks).
///
/// The forecast is rule-based — it says so on the card — built from recent
/// completed sales, Sri Lanka's festival calendar and current supply.
class PriceForecastCard extends StatefulWidget {
  final String cropType;

  /// Called when the farmer taps "Use this as my asking price".
  final ValueChanged<double>? onUsePrice;

  const PriceForecastCard({super.key, required this.cropType, this.onUsePrice});

  @override
  State<PriceForecastCard> createState() => _PriceForecastCardState();
}

class _PriceForecastCardState extends State<PriceForecastCard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PriceForecastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropType != widget.cropType) _load();
  }

  Future<void> _load() async {
    final crop = widget.cropType;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final result = await InsightsApi.getPriceForecast(crop, weeks: 12);
    if (!mounted || crop != widget.cropType) return; // farmer already picked another crop
    setState(() {
      _loading = false;
      if (result["success"] == true && result["data"] is Map) {
        _data = Map<String, dynamic>.from(result["data"] as Map);
      } else {
        _data = null;
        _failed = true;
      }
    });
  }

  String _confidenceLabel(String c) {
    switch (c) {
      case "high":
        return tr("High confidence", "ඉහළ විශ්වාසය");
      case "medium":
        return tr("Medium confidence", "මධ්‍යම විශ්වාසය");
      default:
        return tr("Low confidence", "අඩු විශ්වාසය");
    }
  }

  Color _confidenceColor(String c) {
    switch (c) {
      case "high":
        return AppColors.forest;
      case "medium":
        return AppColors.gold;
      default:
        return AppColors.inkMuted;
    }
  }

  String _driverLabel(String label) {
    if (!isSinhala()) return label;
    final lower = label.toLowerCase();
    if (lower.contains("oversupply")) return "වෙළඳපොළේ අතිරික්ත සැපයුම";
    if (lower.contains("falling supply")) return "සැපයුම අඩුවීම";
    if (lower.contains("festival")) return "උත්සව ඉල්ලුම";
    if (lower.contains("weather")) return "කාලගුණ අවදානම";
    if (lower.contains("disease")) return "රෝග පැතිරීම නිසා සැපයුම අඩුවීම";
    return label;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: ShimmerBox(height: 210, borderRadius: BorderRadius.all(Radius.circular(16))),
      );
    }
    if (_failed || _data == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: InfoBanner(
          icon: Icons.cloud_off_rounded,
          color: AppColors.inkMuted,
          text: tr("The price forecast isn't available right now. You can still set your own price.",
              "මිල අනාවැකිය දැන් ලබා ගත නොහැක. ඔබට තවමත් ඔබේම මිල නියම කළ හැක."),
        ),
      );
    }

    final data = _data!;
    final points = (data["points"] as List).map((p) => Map<String, dynamic>.from(p as Map)).toList();
    final values = points.map((p) => numOf(p["pricePerKg"])).toList();
    final events = points.map((p) => p["event"] != null).toList();
    final today = numOf(data["todayPricePerKg"]);
    final peak = Map<String, dynamic>.from(data["peak"] as Map);
    final peakChange = numOf(peak["changePercent"]);
    final peakDate = DateTime.tryParse("${peak["date"]}");
    final confidence = "${data["confidence"]}";
    final drivers = (data["drivers"] as List? ?? []).map((d) => Map<String, dynamic>.from(d as Map)).toList();
    final thinData = data["baselineSource"] == "no_data_flat_default";
    final weeks = points.length - 1;

    final String outlook;
    if (peakChange >= 1 && peakDate != null) {
      final event = peak["event"] != null ? " · ${peak["event"]}" : "";
      outlook = tr(
        "Peak around ${DateFormat("d MMM").format(peakDate)}: ${lkr(numOf(peak["pricePerKg"]))}/kg (+${peakChange.toStringAsFixed(1)}%)$event",
        "${DateFormat("d MMM").format(peakDate)} පමණ ඉහළම මිල: ${lkr(numOf(peak["pricePerKg"]))}/kg (+${peakChange.toStringAsFixed(1)}%)",
      );
    } else {
      outlook = tr("Prices look steady for the next $weeks weeks.", "ඉදිරි සති $weeks සඳහා මිල ස්ථාවරව පවතී.");
    }

    return SoftCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.forest),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "${tr("Price outlook", "මිල අනාවැකිය")} · ${widget.cropType}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill(label: _confidenceLabel(confidence), color: _confidenceColor(confidence)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(lkr(today), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.forest)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text("/kg ${tr("today", "අද")}", style: TextStyle(fontSize: 12, color: mutedOf(context))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(outlook, style: TextStyle(fontSize: 12.5, color: inkOf(context), height: 1.35)),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _ForecastPainter(
                values: values,
                hasEvent: events,
                lineColor: AppColors.forest,
                gridColor: borderOf(context),
                dotInnerColor: surfaceOf(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr("Today", "අද"), style: TextStyle(fontSize: 10.5, color: mutedOf(context))),
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(tr("Festival demand", "උත්සව ඉල්ලුම"), style: TextStyle(fontSize: 10.5, color: mutedOf(context))),
                ],
              ),
              Text(tr("+$weeks weeks", "+සති $weeks"), style: TextStyle(fontSize: 10.5, color: mutedOf(context))),
            ],
          ),
          if (drivers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: drivers.map((d) {
                final impact = numOf(d["impactPercent"]);
                final color = impact >= 0 ? AppColors.forest : AppColors.danger;
                final sign = impact >= 0 ? "+" : "";
                return StatusPill(label: "${_driverLabel("${d["label"]}")} $sign${impact.toStringAsFixed(1)}%", color: color);
              }).toList(),
            ),
          ],
          if (widget.onUsePrice != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onUsePrice!(today),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(tr("Use ${lkr(today)}/kg as my asking price", "${lkr(today)}/kg මගේ මිල ලෙස යොදන්න")),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            thinData
                ? tr("Not enough sales data for this crop yet — treat this as a rough guide only.",
                    "මෙම බෝගය සඳහා විකුණුම් දත්ත තවම ප්‍රමාණවත් නැත — මෙය දළ මගපෙන්වීමක් ලෙස සලකන්න.")
                : tr("Rule-based estimate from recent sales, the festival calendar, supply and weather. Not a guarantee.",
                    "මෑත විකුණුම්, උත්සව දින දර්ශනය, සැපයුම සහ කාලගුණය මත පදනම් වූ ගණනය කිරීමකි. සහතිකයක් නොවේ."),
            style: TextStyle(fontSize: 11, color: mutedOf(context), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ForecastPainter extends CustomPainter {
  final List<double> values;
  final List<bool> hasEvent;
  final Color lineColor;
  final Color gridColor;
  final Color dotInnerColor;

  _ForecastPainter({
    required this.values,
    required this.hasEvent,
    required this.lineColor,
    required this.gridColor,
    required this.dotInnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const padTop = 20.0;
    const padBottom = 6.0;
    const padH = 8.0;

    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if ((maxV - minV) < 1) {
      // Perfectly flat forecast — give the line some room so it isn't glued to an edge.
      minV -= 5;
      maxV += 5;
    }
    final range = maxV - minV;
    final chartH = size.height - padTop - padBottom;
    final chartW = size.width - padH * 2;

    Offset pointAt(int i) {
      final x = padH + chartW * i / (values.length - 1);
      final y = padTop + chartH * (1 - (values[i] - minV) / range);
      return Offset(x, y);
    }

    // Faint horizontal grid lines.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int g = 0; g < 3; g++) {
      final y = padTop + chartH * g / 2;
      canvas.drawLine(Offset(padH, y), Offset(size.width - padH, y), gridPaint);
    }

    // The smooth price line.
    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < values.length; i++) {
      final a = pointAt(i - 1);
      final b = pointAt(i);
      final midX = (a.dx + b.dx) / 2;
      line.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }

    // Soft gradient under the line.
    final area = Path.from(line)
      ..lineTo(pointAt(values.length - 1).dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.28), lineColor.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Gold dots where a festival lifts demand.
    for (int i = 0; i < values.length; i++) {
      if (i < hasEvent.length && hasEvent[i]) {
        canvas.drawCircle(pointAt(i), 3.8, Paint()..color = AppColors.gold);
      }
    }

    // "Today" marker.
    final start = pointAt(0);
    canvas.drawCircle(start, 5.5, Paint()..color = lineColor);
    canvas.drawCircle(start, 2.6, Paint()..color = dotInnerColor);

    // Label the highest point (if it is meaningfully above today).
    var peakIndex = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[peakIndex]) peakIndex = i;
    }
    if (peakIndex != 0 && values[peakIndex] > values[0] * 1.005) {
      final p = pointAt(peakIndex);
      canvas.drawCircle(p, 4.2, Paint()..color = lineColor);
      final label = TextPainter(
        text: TextSpan(
          text: values[peakIndex].round().toString(),
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: lineColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = math.max(0.0, math.min(p.dx - label.width / 2, size.width - label.width));
      label.paint(canvas, Offset(dx, math.max(0.0, p.dy - label.height - 6)));
    }
  }

  @override
  bool shouldRepaint(covariant _ForecastPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor || oldDelegate.gridColor != gridColor;
  }
}
