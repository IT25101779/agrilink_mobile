import 'package:flutter/material.dart';
import '../localization/chat_labels.dart';
import '../localization/crop_names.dart';
import '../localization/tr.dart';
import '../services/crop_recommendation_service.dart';
import '../services/group_chat_api.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/ui_kit.dart';
import 'group_chat_screen.dart';

/// The "Community" tab: your groups, suggestions for you, and a finder with
/// area + crop filters. Everyone chats anonymously.
class ChatHubScreen extends StatefulWidget {
  const ChatHubScreen({super.key});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _mine = [];
  List<Map<String, dynamic>> _suggested = [];

  String? _filterDistrict;
  String? _filterCrop; // English crop name, as the server expects
  bool _searching = false;
  List<Map<String, dynamic>>? _results;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _asList(dynamic value) => (value as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _load() async {
    final mine = await GroupChatApi.myGroups();
    final suggested = await GroupChatApi.suggested();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (mine["success"] == true) {
        _mine = _asList(mine["data"]);
        _error = null;
      } else {
        _error = "${mine["message"] ?? ""}";
      }
      if (suggested["success"] == true) _suggested = _asList(suggested["data"]);
    });
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    final result = await GroupChatApi.search(district: _filterDistrict, crop: _filterCrop);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = result["success"] == true ? _asList(result["data"]) : [];
    });
  }

  Future<void> _open(Map<String, dynamic> group) async {
    if (group["joined"] == false || group["alias"] == null) {
      final joined = await GroupChatApi.join("${group["key"]}");
      if (joined["success"] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chatErrorText(joined["code"] as String?, "${joined["message"] ?? ""}"))));
        return;
      }
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)));
    _load();
    if (_results != null) _search();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          FadeSlideIn(child: _privacyBanner(context)),
          const SizedBox(height: 18),
          _heading(tr("My groups", "මගේ කණ්ඩායම්", "என் குழுக்கள்")),
          if (_loading)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
          else if (_error != null && _mine.isEmpty)
            _note(tr("Couldn't load groups. Pull down to try again.", "කණ්ඩායම් පූරණය කළ නොහැක. නැවත උත්සාහ කිරීමට පහළට ඇද්දන්න.", "குழுக்களை ஏற்ற முடியவில்லை. மீண்டும் முயல கீழே இழுக்கவும்."))
          else if (_mine.isEmpty)
            _note(tr("You haven't joined a group yet.", "ඔබ තවම කිසිදු කණ්ඩායමකට සම්බන්ධ වී නැත.", "நீங்கள் இன்னும் எந்தக் குழுவிலும் சேரவில்லை."))
          else
            for (var i = 0; i < _mine.length; i++) FadeSlideIn(delayMs: 60 * i, child: _groupCard(_mine[i], joined: true)),
          if (_suggested.isNotEmpty) ...[
            const SizedBox(height: 18),
            _heading(tr("Suggested for you", "ඔබට යෝග්‍ය", "உங்களுக்குப் பரிந்துரை")),
            for (var i = 0; i < _suggested.length; i++) FadeSlideIn(delayMs: 60 * i, child: _groupCard(_suggested[i], joined: false)),
          ],
          const SizedBox(height: 18),
          _heading(tr("Find a group", "කණ්ඩායමක් සොයන්න", "குழுவைத் தேடு")),
          _finder(context),
        ],
      ),
    );
  }

  Widget _privacyBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0B5D3B), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text("🕶️", style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr("Chat with farmers like you — anonymously.", "ඔබ වැනි ගොවීන් සමඟ නිර්නාමිකව කතා කරන්න.", "உங்களைப் போன்ற விவசாயிகளுடன் பெயர் தெரியாமல் உரையாடுங்கள்."), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  tr("Your real name and phone number are never shown. You appear with a random name in each group.", "ඔබේ සැබෑ නම සහ දුරකථන අංකය කිසිවිටෙකත් නොපෙන්වයි. සෑම කණ්ඩායමකම ඔබට අහඹු නමක් ලැබේ.", "உங்கள் உண்மையான பெயரும் தொலைபேசி எண்ணும் காட்டப்படாது. ஒவ்வொரு குழுவிலும் உங்களுக்கு ஒரு சீரற்ற பெயர் இருக்கும்."),
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: Theme.of(context).textTheme.titleMedium));

  Widget _note(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(text, style: TextStyle(color: mutedOf(context))));

  Widget _groupCard(Map<String, dynamic> group, {required bool joined}) {
    final scope = group["scope"] as String?;
    final color = groupColor(scope);
    final unread = (group["unread"] as num?)?.toInt() ?? 0;
    final members = (group["memberCount"] as num?)?.toInt() ?? 0;
    final last = group["last"] as Map<String, dynamic>?;
    final lastText = last == null
        ? groupSubtitle(group)
        : "${last["alias"]}: ${last["type"] == "image" ? "📷" : last["type"] == "voice" ? "🎤" : last["type"] == "scan" ? "🔬" : "${last["text"] ?? ""}"}";
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: () => _open(group),
        child: Row(
          children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: tintOf(context, color), borderRadius: BorderRadius.circular(14)), child: Icon(groupIcon(scope), color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(groupTitle(group), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(lastText, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
                  const SizedBox(height: 2),
                  Text(tr("$members members", "සාමාජිකයන් $members", "உறுப்பினர்கள் $members"), style: TextStyle(fontSize: 11.5, color: mutedOf(context))),
                ],
              ),
            ),
            if (joined && unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(12)),
                child: Text("$unread", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              )
            else if (!joined)
              Text(tr("Join", "එක්වන්න", "சேர்"), style: const TextStyle(color: AppColors.forest, fontWeight: FontWeight.w800))
            else
              Icon(Icons.chevron_right_rounded, color: mutedOf(context)),
          ],
        ),
      ),
    );
  }

  Widget _finder(BuildContext context) {
    final crops = List<CropOption>.from(CropRecommendationService.catalogue)..sort((a, b) => a.name.compareTo(b.name));
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String?>(
            value: _filterDistrict,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr("Area", "ප්‍රදේශය", "பகுதி"), prefixIcon: const Icon(Icons.place_rounded)),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(tr("Any area", "ඕනෑම ප්‍රදේශයක්", "எந்தப் பகுதியும்"))),
              ...kChatDistricts.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d))),
            ],
            onChanged: (value) => setState(() => _filterDistrict = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _filterCrop,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr("Crop", "බෝගය", "பயிர்"), prefixIcon: const Icon(Icons.grass_rounded)),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(tr("Any crop", "ඕනෑම බෝගයක්", "எந்தப் பயிரும்"))),
              ...crops.map((c) => DropdownMenuItem<String?>(value: c.name, child: Text(cropLocalName(c), overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (value) => setState(() => _filterCrop = value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _searching ? null : _search,
              icon: _searching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search_rounded),
              label: Text(tr("Search", "සොයන්න", "தேடு")),
            ),
          ),
          if (_results != null) ...[
            const SizedBox(height: 14),
            for (final group in _results!) _groupCard(group, joined: group["joined"] == true),
          ],
        ],
      ),
    );
  }
}
