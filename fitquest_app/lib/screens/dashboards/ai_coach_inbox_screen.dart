import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/ai_coach_service.dart';

class AICoachInboxScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const AICoachInboxScreen({super.key, required this.userData, required this.password});

  @override
  State<AICoachInboxScreen> createState() => _AICoachInboxScreenState();
}

class _AICoachInboxScreenState extends State<AICoachInboxScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    try {
      final msgs = await AICoachService.fetchMessages(
          widget.userData['username'], widget.password);
      setState(() { _messages = msgs; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _markAsRead(int id) async {
    try {
      await AICoachService.markAsRead(
          widget.userData['username'], widget.password, id);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: Text('AI COACH INBOX', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : _messages.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildMessageCard(_messages[i]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 80, color: Colors.purpleAccent),
          const SizedBox(height: 20),
          Text('SYSTEMS CLEAR', style: GoogleFonts.rajdhani(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('No new AI coach interventions.', style: TextStyle(color: FQColors.muted)),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> msg) {
    final bool isRead = msg['is_read'] == true;
    final String type = msg['intervention_type'] ?? 'recovery';
    
    return GestureDetector(
      onTap: () => _markAsRead(msg['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isRead ? FQColors.surface : Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isRead ? FQColors.border : Colors.purpleAccent.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt, color: Colors.purpleAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(type.toUpperCase(), style: GoogleFonts.rajdhani(
                        color: Colors.purpleAccent, fontSize: 12,
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
                    if (!isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Text(msg['message'], style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 12),
                  Text(msg['created_at'].toString().substring(0, 10),
                      style: const TextStyle(color: FQColors.muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
