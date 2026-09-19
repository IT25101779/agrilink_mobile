import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/insights_api.dart';
import '../theme/app_theme.dart';
import '../widgets/crop_picker_field.dart';
import '../widgets/crop_thumbnail.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/ui_kit.dart';

/// GROUP SELLING. Buyers such as hotels want hundreds of kg, but a smallholder
/// may only have 60-80 kg. Here neighbouring farmers pool their harvest into
/// one "lot"; when it is full a buyer claims the whole lot and each farmer is
/// paid for the kg they put in.
class GroupLotsScreen extends StatefulWidget {
  const GroupLotsScreen({super.key});

  @override
  State<GroupLotsScreen> createState() => _GroupLotsScreenState();
}

class _GroupLotsScreenState extends State<GroupLotsScreen> {
  List<Map<String, dynamic>> _lots = [];
  bool _loading = true;
  bool _mineOnly = false;
  String? _district;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _district = await AuthService.getDistrict();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await InsightsApi.listLots(district: _district, mine: _mineOnly);
    if (!mounted) return;
    setState(() {
      _lots = result["success"] == true
          ? (result["data"] as List).map((l) => Map<String, dynamic>.from(l as Map)).toList()
          : [];
      _loading = false;
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _join(Map<String, dynamic> lot) async {
    final remaining = numOf(lot["remainingKg"]);
    final controller = TextEditingController(text: priceText(remaining < 50 ? remaining : 50));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(lot["isMember"] == true ? tr("Add more to this lot", "මෙම ලොට් එකට තවත් එක් කරන්න") : tr("Join this lot", "මෙම ලොට් එකට එක්වන්න")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr("${priceText(remaining)} kg of ${lot["cropType"]} is still needed.", "${lot["cropType"]} කි.ග්‍රෑ. ${priceText(remaining)} ක් තවම අවශ්‍යයි."),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr("Your quantity (kg)", "ඔබේ ප්‍රමාණය (කි.ග්‍රෑ.)"), border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Cancel", "අවලංගු"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Join", "එක්වන්න"))),
        ],
      ),
    );
    final quantity = double.tryParse(controller.text);
    controller.dispose();
    if (confirmed != true || quantity == null || quantity < 1) return;

    final result = await InsightsApi.joinLot("${lot["_id"]}", quantity);
    _toast(result["message"]?.toString() ?? tr("Something went wrong.", "යම්කිසි දෝෂයක් සිදු විය."));
    _load();
  }

  Future<void> _confirmAndRun(String title, String body, Future<Map<String, dynamic>> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Back", "ආපසු"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Yes", "ඔව්"))),
        ],
      ),
    );
    if (ok != true) return;
    final result = await action();
    _toast(result["message"]?.toString() ?? tr("Done.", "සම්පූර්ණයි."));
    _load();
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => const _CreateLotSheet(),
    );
    if (created == true) {
      _toast(tr("Group lot created. Neighbours can now join it.", "කණ්ඩායම් ලොට් එක සාදන ලදී. අසල්වැසියන්ට දැන් එක්විය හැක."));
      _load();
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12.5)),
        selected: selected,
        selectedColor: AppColors.forest,
        labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _lotCard(Map<String, dynamic> lot) {
    final status = "${lot["status"]}";
    final crop = CropPickerField.findCrop("${lot["cropType"]}");
    final committed = numOf(lot["committedKg"]);
    final target = numOf(lot["targetKg"], 1);
    final isMember = lot["isMember"] == true;
    final isOrganizer = lot["isOrganizer"] == true;
    final members = (lot["members"] as List? ?? []).map((m) => Map<String, dynamic>.from(m as Map)).toList();
    final memberCount = (lot["memberCount"] as num?)?.toInt() ?? members.length;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case "open":
        statusColor = AppColors.forest;
        statusLabel = tr("Open", "විවෘතයි");
        break;
      case "full":
        statusColor = AppColors.gold;
        statusLabel = tr("Full · waiting for a buyer", "පිරී ඇත · ගැනුම්කරුවෙකු බලාපොරොත්තුවෙන්");
        break;
      case "claimed":
        statusColor = AppColors.indigo;
        statusLabel = tr("Claimed by a buyer", "ගැනුම්කරුවෙකු ගෙන ඇත");
        break;
      default:
        statusColor = AppColors.inkMuted;
        statusLabel = status == "expired" ? tr("Expired", "කල් ඉකුත්") : tr("Cancelled", "අවලංගුයි");
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (crop != null)
                CropThumbnail(wikiImageTitle: crop.wikiImageTitle, size: 48)
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: tintOf(context, AppColors.forest), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.eco_rounded, color: AppColors.forest),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${lot["cropType"]}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      "${lot["district"]} · ${tr("organised by", "සංවිධායක")} ${lot["organizer"]}",
                      style: TextStyle(fontSize: 12, color: mutedOf(context)),
                    ),
                    if (status == "open")
                      Text(closesInText("${lot["closesAt"]}", si: isSinhala()), style: TextStyle(fontSize: 12, color: mutedOf(context))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("LKR ${priceText(numOf(lot["pricePerKg"]))}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.forest)),
                  Text("/kg", style: TextStyle(fontSize: 11, color: mutedOf(context))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          RoundedBar(value: committed / target, color: status == "full" ? AppColors.gold : AppColors.forest, height: 10),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${priceText(committed)} / ${priceText(target)} kg", style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              Text(tr("$memberCount farmer${memberCount == 1 ? "" : "s"}", "ගොවීන් $memberCount"), style: TextStyle(fontSize: 12, color: mutedOf(context))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill(label: statusLabel, color: statusColor),
              if (isMember)
                StatusPill(
                  label: tr("You: ${priceText(numOf(lot["myQuantityKg"]))} kg", "ඔබ: ${priceText(numOf(lot["myQuantityKg"]))} කි.ග්‍රෑ."),
                  color: AppColors.indigo,
                  icon: Icons.check_rounded,
                ),
            ],
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              members.map((m) => "${m["name"]} ${priceText(numOf(m["quantityKg"]))}kg").join(" · "),
              style: TextStyle(fontSize: 11.5, color: mutedOf(context), height: 1.35),
            ),
          ],
          if ("${lot["pickupNote"]}".isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 14, color: mutedOf(context)),
                const SizedBox(width: 4),
                Expanded(child: Text("${lot["pickupNote"]}", style: TextStyle(fontSize: 11.5, color: mutedOf(context)))),
              ],
            ),
          ],
          if (status == "open") ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _join(lot),
                    child: Text(isMember ? tr("Add more", "තව එක් කරන්න") : tr("Join lot", "ලොට් එකට එක්වන්න")),
                  ),
                ),
                if (isMember && !isOrganizer) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _confirmAndRun(
                      tr("Leave this lot?", "මෙම ලොට් එකෙන් ඉවත් වන්නද?"),
                      tr("Your kg will be removed from the lot.", "ඔබේ ප්‍රමාණය ලොට් එකෙන් ඉවත් කරනු ලැබේ."),
                      () => InsightsApi.leaveLot("${lot["_id"]}"),
                    ),
                    child: Text(tr("Leave", "ඉවත් වන්න")),
                  ),
                ],
                if (isOrganizer && memberCount == 1) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _confirmAndRun(
                      tr("Cancel this lot?", "මෙම ලොට් එක අවලංගු කරන්නද?"),
                      tr("No one else has joined yet, so it will simply be removed.", "තවම කිසිවෙකු එක් වී නැති නිසා එය ඉවත් කරනු ලැබේ."),
                      () => InsightsApi.cancelLot("${lot["_id"]}"),
                    ),
                    child: Text(tr("Cancel", "අවලංගු")),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              InfoBanner(
                icon: Icons.groups_rounded,
                text: tr(
                  "Only have a small harvest? Pool it with neighbours. Hotels and supermarkets buy whole lots, and you are paid for the kg you put in.",
                  "අස්වැන්න අඩුද? අසල්වැසියන් සමඟ එකතු කරන්න. හෝටල් සහ සුපිරි වෙළඳසැල් සම්පූර්ණ ලොට් මිලදී ගන්නා අතර, ඔබ දුන් ප්‍රමාණයට ඔබට ගෙවනු ලැබේ.",
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openCreateSheet,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(tr("Start a group lot", "කණ්ඩායම් ලොට් එකක් අරඹන්න")),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _chip(_district != null && _district!.isNotEmpty ? tr("Near me ($_district)", "මා අසල ($_district)") : tr("All lots", "සියලු ලොට්"), !_mineOnly, () {
                    setState(() => _mineOnly = false);
                    _load();
                  }),
                  _chip(tr("My lots", "මගේ ලොට්"), _mineOnly, () {
                    setState(() => _mineOnly = true);
                    _load();
                  }),
                ],
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Column(children: [ShimmerCard(), ShimmerCard()])
              else if (_lots.isEmpty)
                EmptyState(
                  icon: Icons.groups_outlined,
                  title: tr("No group lots yet", "තවම කණ්ඩායම් ලොට් නැත"),
                  subtitle: tr("Start one and invite your neighbours to join.", "එකක් අරඹා අසල්වැසියන්ට එක්වීමට ආරාධනා කරන්න."),
                )
              else
                ..._lots.map(_lotCard),
            ],
          ),
        );
      },
    );
  }
}

class _CreateLotSheet extends StatefulWidget {
  const _CreateLotSheet();

  @override
  State<_CreateLotSheet> createState() => _CreateLotSheetState();
}

class _CreateLotSheetState extends State<_CreateLotSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _targetController = TextEditingController();
  final _priceController = TextEditingController();
  final _ownController = TextEditingController();
  final _noteController = TextEditingController();
  int _days = 5;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _cropController.dispose();
    _targetController.dispose();
    _priceController.dispose();
    _ownController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await InsightsApi.createLot(
      cropType: _cropController.text.trim(),
      targetKg: double.parse(_targetController.text),
      pricePerKg: double.parse(_priceController.text),
      quantityKg: double.parse(_ownController.text),
      closesInDays: _days,
      pickupNote: _noteController.text.trim(),
    );
    if (!mounted) return;
    if (result["success"] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = result["message"]?.toString() ?? "Could not create the lot.";
      });
    }
  }

  String? _numberValidator(String? v) => (v == null || double.tryParse(v) == null) ? tr("Enter a valid number", "වලංගු අංකයක් ඇතුළත් කරන්න") : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr("Start a group lot", "කණ්ඩායම් ලොට් එකක් අරඹන්න"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              CropPickerField(
                controller: _cropController,
                label: tr("Crop", "බෝගය"),
                validator: (v) => (v == null || v.isEmpty) ? tr("Required", "අවශ්‍යයි") : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr("Lot size to reach (kg, at least 50)", "ලොට් එකේ ඉලක්කය (කි.ග්‍රෑ., අවම 50)"), border: const OutlineInputBorder()),
                validator: (v) {
                  final n = double.tryParse(v ?? "");
                  if (n == null) return tr("Enter a valid number", "වලංගු අංකයක් ඇතුළත් කරන්න");
                  if (n < 50) return tr("At least 50 kg", "අවම වශයෙන් කි.ග්‍රෑ. 50");
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr("Asking price per kg (LKR)", "කි.ග්‍රෑ. එකක මිල (LKR)"), border: const OutlineInputBorder()),
                validator: _numberValidator,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ownController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: tr("How many kg will YOU add?", "ඔබ කි.ග්‍රෑ. කීයක් එක් කරනවාද?"), border: const OutlineInputBorder()),
                validator: (v) {
                  final own = double.tryParse(v ?? "");
                  final target = double.tryParse(_targetController.text);
                  if (own == null || own < 1) return tr("Enter a valid number", "වලංගු අංකයක් ඇතුළත් කරන්න");
                  if (target != null && own > target) return tr("More than the lot size", "ලොට් එකේ ප්‍රමාණයට වඩා වැඩියි");
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                decoration: InputDecoration(labelText: tr("Pickup place / note (optional)", "රැගෙන යන ස්ථානය / සටහන (අත්‍යවශ්‍ය නොවේ)"), border: const OutlineInputBorder()),
              ),
              Text(tr("Lot stays open for", "ලොට් එක විවෘතව තබන කාලය"), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: mutedOf(context))),
              const SizedBox(height: 6),
              Wrap(
                children: [3, 5, 7].map((d) {
                  final selected = _days == d;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tr("$d days", "දින $d")),
                      selected: selected,
                      selectedColor: AppColors.forest,
                      labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
                      onSelected: (_) => setState(() => _days = d),
                    ),
                  );
                }).toList(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(tr("Create lot", "ලොට් එක සාදන්න")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
