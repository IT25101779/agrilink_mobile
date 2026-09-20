import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/help_widgets.dart';
import '../widgets/ui_kit.dart';

/// "Elephants near my field tonight" - warn neighbours within 8 km, and see what others reported nearby.
class WildlifeScreen extends StatefulWidget {
  const WildlifeScreen({super.key});

  @override
  State<WildlifeScreen> createState() => _WildlifeScreenState();
}

class _WildlifeScreenState extends State<WildlifeScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  Position? _pos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return false;
      _pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 12));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final located = await _locate();
    if (!located) {
      if (mounted) setState(() {
        _loading = false;
        _error = tr("We need your location to show animals near you. Please allow location and pull down to retry.", "ඔබ අවට සතුන් පෙන්වීමට ඔබේ ස්ථානය අවශ්‍යයි. කරුණාකර ස්ථානය ඉඩ දී නැවත උත්සාහ කරන්න.", "அருகிலுள்ள விலங்குகளைக் காட்ட உங்கள் இடம் தேவை. இடத்தை அனுமதித்து மீண்டும் முயலவும்.");
      });
      return;
    }
    final r = await HelpApi.nearbyWildlife(_pos!.latitude, _pos!.longitude);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true) {
        _items = (r["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = apiMessage(r);
      }
    });
  }

  Future<void> _report() async {
    if (_pos == null && !await _locate()) {
      showSnack(context, tr("Location is needed to send a warning.", "අනතුරු ඇඟවීමට ස්ථානය අවශ්‍යයි.", "எச்சரிக்கைக்கு இடம் தேவை."));
      return;
    }
    final note = TextEditingController();
    String species = "elephant";
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr("Warn my neighbours", "අසල්වැසියන්ට අනතුරු අඟවන්න", "அண்டை வீட்டாரை எச்சரிக்கவும்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 4),
            Text(tr("Farmers within 8 km will get a message. Only send it if you really saw them.", "කි.මී. 8ක් ඇතුළත ගොවීන්ට පණිවිඩයක් යයි. ඇත්තටම දුටුවා නම් පමණක් යවන්න.", "8 கி.மீ க்குள் உள்ள விவசாயிகளுக்கு செய்தி போகும். உண்மையாகப் பார்த்திருந்தால் மட்டும் அனுப்பவும்."), style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: kSpeciesEmoji.keys.map((s) => ChoiceChip(label: Text("${kSpeciesEmoji[s]} ${speciesLabel(s)}"), selected: species == s, onSelected: (_) => setS(() => species = s))).toList()),
            const SizedBox(height: 10),
            TextField(controller: note, maxLength: 160, decoration: InputDecoration(labelText: tr("Short note (optional)", "කෙටි සටහන (විකල්ප)", "சிறு குறிப்பு (விருப்பம்)"), border: const OutlineInputBorder())),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.campaign_rounded), label: Text(tr("Send warning", "අනතුරු ඇඟවීම යවන්න", "எச்சரிக்கை அனுப்பு")))),
          ]),
        ),
      ),
    );
    if (send != true) return;
    final r = await HelpApi.reportWildlife(species, _pos!.latitude, _pos!.longitude, note.text.trim());
    if (!mounted) return;
    if (r["success"] == true) {
      showSnack(context, r["queued"] == true ? apiMessage(r) : tr("Warning sent. Thank you!", "අනතුරු ඇඟවීම යැවුවා. ස්තූතියි!", "எச்சரிக்கை அனுப்பப்பட்டது. நன்றி!"));
      _load();
    } else {
      showSnack(context, apiMessage(r));
    }
  }

  Future<void> _confirm(Map<String, dynamic> s, String kind) async {
    final r = await HelpApi.confirmWildlife(s["id"], kind);
    if (!mounted) return;
    showSnack(context, r["success"] == true ? tr("Thanks!", "ස්තූතියි!", "நன்றி!") : apiMessage(r));
    if (r["success"] == true) _load();
  }

  String _ago(int min) => min < 60 ? tr("$min min ago", "මිනිත්තු $min කට පෙර", "$min நிமிடம் முன்") : tr("${(min / 60).round()} h ago", "පැය ${(min / 60).round()} කට පෙර", "${(min / 60).round()} மணி முன்");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Wildlife alerts", "සත්ව අනතුරු ඇඟවීම්", "வனவிலங்கு எச்சரிக்கைகள்"))),
      floatingActionButton: FloatingActionButton.extended(onPressed: _report, icon: const Icon(Icons.campaign_rounded), label: Text(tr("I saw animals", "සතුන් දුටුවා", "விலங்குகளைப் பார்த்தேன்"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
          InfoBanner(icon: Icons.shield_moon_rounded, text: tr("Reports last 48 hours. Farmers within 8 km of a sighting are warned automatically.", "වාර්තා පැය 48ක් පවතී. දුටු ස්ථානයේ සිට කි.මී. 8ක් ඇතුළත ගොවීන්ට ස්වයංක්‍රීයව දැනුම් දෙයි.", "அறிக்கைகள் 48 மணி நேரம் இருக்கும். 8 கி.மீ க்குள் உள்ள விவசாயிகளுக்கு தானாகத் தெரிவிக்கப்படும்.")),
          const SizedBox(height: 12),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.location_off_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && _items.isEmpty) emptyState(Icons.check_circle_outline_rounded, tr("All quiet nearby", "අවට සන්සුන්", "அருகில் அமைதி"), tr("No animals reported within 12 km in the last 48 hours.", "පසුගිය පැය 48 තුළ කි.මී. 12ක් ඇතුළත වාර්තා නැත.", "கடந்த 48 மணி நேரத்தில் 12 கி.மீ க்குள் எதுவும் இல்லை.")),
          ..._items.map((s) => SoftCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(kSpeciesEmoji[s["species"]] ?? "🐾", style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(speciesLabel("${s["species"]}"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text("${numOf(s["distanceKm"]).toStringAsFixed(1)} km • ${_ago((s["minutesAgo"] as num).toInt())} • ${s["seenBy"]} ${tr("seen", "දුටු", "பார்த்தனர்")}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                    ])),
                    if ((s["allClear"] as num) > 0) StatusPill(label: "${s["allClear"]} ${tr("all clear", "ආරක්ෂිතයි", "பாதுகாப்பு")}", color: AppColors.forest),
                  ]),
                  if ("${s["note"]}".isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text("${s["note"]}", style: const TextStyle(fontSize: 13))),
                  if (s["mine"] != true) Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      OutlinedButton(onPressed: () => _confirm(s, "seen"), child: Text(tr("I saw them too", "මමත් දුටුවා", "நானும் பார்த்தேன்"))),
                      const SizedBox(width: 8),
                      OutlinedButton(onPressed: () => _confirm(s, "clear"), child: Text(tr("All clear now", "දැන් ආරක්ෂිතයි", "இப்போது பாதுகாப்பு"))),
                    ]),
                  ),
                ]),
              )),
        ]),
      ),
    );
  }
}
