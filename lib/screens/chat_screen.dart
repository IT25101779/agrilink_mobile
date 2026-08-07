import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';

class ChatMessage {
  final String role; // "user" or "assistant"
  final String content;
  ChatMessage({required this.role, required this.content});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isSending = false;
  bool _isLoadingHistory = true;
  bool _isListening = false;
  bool _autoReadReplies = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    VoiceService.stopListening();
    VoiceService.stopSpeaking();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final farmerId = await AuthService.getUserId();
    if (farmerId == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }
    final result = await ApiService.getChatHistory(farmerId);
    if (result["success"] == true) {
      final history = (result["data"] as List)
          .map((m) => ChatMessage(role: m["role"], content: m["content"]))
          .toList();
      setState(() {
        _messages.addAll(history);
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await VoiceService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    final started = await VoiceService.startListening(
      onResult: (text) {
        setState(() => _messageController.text = text);
      },
      onDone: () {
        setState(() => _isListening = false);
      },
    );

    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Voice input isn't available on this device/browser. Please type instead.")),
        );
      }
      return;
    }

    setState(() => _isListening = true);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_isListening) {
      await VoiceService.stopListening();
      setState(() => _isListening = false);
    }

    setState(() {
      _messages.add(ChatMessage(role: "user", content: text));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    final farmerId = await AuthService.getUserId() ?? "";
    final result = await ApiService.sendChatMessage(
      farmerId: farmerId,
      message: text,
      language: AppLocale.instance.languageCode,
    );

    setState(() => _isSending = false);

    if (result["success"] == true) {
      final reply = result["data"]["reply"] as String;
      setState(() => _messages.add(ChatMessage(role: "assistant", content: reply)));
      _scrollToBottom();
      if (_autoReadReplies) VoiceService.speak(reply);
    } else if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          role: "assistant",
          content: "Sorry, I couldn't respond right now (${result["message"] ?? "connection issue"}). Please try again.",
        ));
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        final isEnglish = AppLocale.instance.languageCode == "en";

        return Scaffold(
          appBar: AppBar(
            title: Text(t("agriAssistant")),
            actions: [
              GestureDetector(
                onTap: () => AppLocale.instance.setLanguage(isEnglish ? "si" : "en"),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(isEnglish ? "EN" : "සිං", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              IconButton(
                icon: Icon(_autoReadReplies ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 21),
                tooltip: "Auto read-aloud replies",
                onPressed: () => setState(() => _autoReadReplies = !_autoReadReplies),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                t("chatPlaceholder"),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.inkMuted),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isUser = msg.role == "user";
                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                      decoration: BoxDecoration(
                                        color: isUser ? AppColors.forest : AppColors.forestLight,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        msg.content,
                                        style: TextStyle(color: isUser ? Colors.white : AppColors.ink),
                                      ),
                                    ),
                                    if (!isUser)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                                        child: GestureDetector(
                                          onTap: () => VoiceService.speak(msg.content),
                                          child: const Icon(Icons.volume_up_rounded, size: 16, color: AppColors.inkMuted),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              if (_isSending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(t("assistantTyping"), style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                ),
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mic_rounded, size: 14, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Text(t("listening"), style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleListening,
                        child: CircleAvatar(
                          backgroundColor: _isListening ? AppColors.danger : AppColors.forestLight,
                          child: Icon(Icons.mic_rounded, color: _isListening ? Colors.white : AppColors.forest, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: t("typeYourQuestion"),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.forest,
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
