import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/quest_service.dart';
import '../../services/api_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 1.  QUEST SCREEN — Coach's quest board
// ══════════════════════════════════════════════════════════════════════════════
class QuestScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const QuestScreen({super.key, required this.userData, required this.password});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  List<dynamic> _quests  = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  void _loadQuests() async {
    try {
      final q = await QuestService.fetchMyQuests(
          widget.userData['username'], widget.password);
      if (mounted) setState(() { _quests = q; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _openBuilder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => QuestBuilderScreen(
              userData: widget.userData, password: widget.password)),
    );
    if (result == true) _loadQuests();
  }

  void _showAssignSheet(Map<String, dynamic> quest) async {
    try {
      final roster = await ApiService.fetchMyRoster(
          widget.userData['username'], widget.password);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AssignQuestSheet(
          quest:    quest,
          athletes: roster,
          userData: widget.userData,
          password: widget.password,
          onAssigned: _loadQuests,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
    }
  }

  void _deleteQuest(Map<String, dynamic> quest) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        title: const Text('Delete Quest',
            style: TextStyle(color: Colors.white)),
        content: Text('Delete "${quest['title']}"?',
            style: const TextStyle(color: FQColors.muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: FQColors.muted))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await QuestService.deleteQuest(
          widget.userData['username'], widget.password, quest['id']);
      _loadQuests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoQuests   = _quests.where((q) => q['is_auto_generated'] == true).toList();
    final customQuests = _quests.where((q) => q['is_auto_generated'] != true).toList();

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: const Text('QUEST BOARD'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadQuests)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuilder,
        backgroundColor: FQColors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('NEW QUEST',
            style: GoogleFonts.rajdhani(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.purple))
          : _quests.isEmpty
              ? _emptyState()
              : CustomScrollView(
                  slivers: [
                    // DAILY PLANS section (auto-generated)
                    if (autoQuests.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(children: [
                            const Icon(Icons.auto_awesome,
                                color: FQColors.cyan, size: 14),
                            const SizedBox(width: 6),
                            Text('DAILY PLANS',
                                style: GoogleFonts.rajdhani(
                                    color: FQColors.cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: FQColors.cyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${autoQuests.length}',
                                  style: const TextStyle(
                                      color: FQColors.cyan, fontSize: 10)),
                            ),
                          ]),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _AutoQuestRow(
                            quest: autoQuests[i],
                            onDelete: () => _deleteQuest(autoQuests[i]),
                          ),
                          childCount: autoQuests.length,
                        ),
                      ),
                    ],

                    // CUSTOM QUESTS section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(children: [
                          const Icon(Icons.military_tech_outlined,
                              color: FQColors.gold, size: 14),
                          const SizedBox(width: 6),
                          Text('CUSTOM QUESTS',
                              style: GoogleFonts.rajdhani(
                                  color: FQColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                        ]),
                      ),
                    ),
                    if (customQuests.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text('No custom quests yet. Tap NEW QUEST to add one.',
                              style: TextStyle(color: FQColors.muted, fontSize: 12)),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: _QuestTile(
                              quest:    customQuests[i],
                              onAssign: () => _showAssignSheet(customQuests[i]),
                              onDelete: () => _deleteQuest(customQuests[i]),
                            ),
                          ),
                          childCount: customQuests.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.military_tech_outlined,
              size: 56, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No quests yet',
              style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Tap "NEW QUEST" to create a challenge',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
}

// ── Auto Quest Row (compact, for daily plans) ─────────────────────────────────
class _AutoQuestRow extends StatelessWidget {
  final Map<String, dynamic> quest;
  final VoidCallback onDelete;

  const _AutoQuestRow({required this.quest, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final assignedCount = quest['assigned_count'] ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FQColors.border),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: FQColors.cyan, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(quest['title'] ?? '',
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: FQColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text('+${quest['xp_reward']} XP',
              style: const TextStyle(color: FQColors.gold, fontSize: 10)),
        ),
        const SizedBox(width: 6),
        Text('$assignedCount',
            style: const TextStyle(color: FQColors.muted, fontSize: 11)),
        const Icon(Icons.group_outlined, color: FQColors.muted, size: 13),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onDelete,
          child: const Icon(Icons.delete_outline,
              color: FQColors.muted, size: 16),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2.  QUEST BUILDER — Create a new quest
// ══════════════════════════════════════════════════════════════════════════════
class QuestBuilderScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const QuestBuilderScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<QuestBuilderScreen> createState() => _QuestBuilderScreenState();
}

class _QuestBuilderScreenState extends State<QuestBuilderScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _xpCtrl    = TextEditingController(text: '100');
  final _coinCtrl  = TextEditingController(text: '10');
  String _difficulty   = 'MEDIUM';
  bool   _isSaving     = false;
  bool   _isCommunity  = false;

  static const _difficulties = ['EASY', 'MEDIUM', 'HARD'];

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _xpCtrl.dispose(); _coinCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a quest title')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final created = await QuestService.createQuestWithId(
          widget.userData['username'], widget.password, {
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'xp_reward':   int.tryParse(_xpCtrl.text) ?? 100,
        'coin_reward': int.tryParse(_coinCtrl.text) ?? 10,
        'difficulty':  _difficulty,
      });
      // If community quest, immediately assign to all athletes
      if (_isCommunity && created != null) {
        await QuestService.assignQuest(
            widget.userData['username'], widget.password,
            created['id'], [], isCommunity: true);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: const Text('NEW QUEST'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: FQColors.purple, strokeWidth: 2)))
              : TextButton(
                  onPressed: _save,
                  child: Text('SAVE',
                      style: GoogleFonts.rajdhani(
                          color: FQColors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 15))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('QUEST DETAILS'),
          const SizedBox(height: 12),
          _field(_titleCtrl, 'Quest Title', Icons.military_tech_outlined,
              FQColors.purple),
          const SizedBox(height: 12),
          _field(_descCtrl, 'Description (optional)', Icons.description_outlined,
              FQColors.muted, maxLines: 3),
          const SizedBox(height: 24),
          _sectionLabel('REWARDS'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _field(_xpCtrl, 'XP Reward', Icons.bolt,
                    FQColors.gold, isNumber: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _field(_coinCtrl, 'Coin Reward', Icons.monetization_on_outlined,
                    FQColors.cyan, isNumber: true)),
          ]),
          const SizedBox(height: 24),
          _sectionLabel('DIFFICULTY'),
          const SizedBox(height: 12),
          Row(children: _difficulties.map((d) {
            final selected = _difficulty == d;
            final color = d == 'EASY'
                ? FQColors.green
                : d == 'MEDIUM'
                    ? FQColors.gold
                    : FQColors.red;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _difficulty = d),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? color.withOpacity(0.15) : FQColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected ? color : FQColors.border),
                  ),
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                          color: selected ? color : FQColors.muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 24),
          _sectionLabel('SCOPE'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: FQColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isCommunity
                      ? FQColors.purple.withOpacity(0.4)
                      : FQColors.border),
            ),
            child: SwitchListTile(
              value: _isCommunity,
              onChanged: (v) => setState(() => _isCommunity = v),
              activeColor: FQColors.purple,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text('COMMUNITY QUEST',
                  style: GoogleFonts.rajdhani(
                      color: _isCommunity ? FQColors.purple : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5)),
              subtitle: const Text('Assign to all athletes immediately',
                  style: TextStyle(color: FQColors.muted, fontSize: 11)),
            ),
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.rajdhani(
          color: FQColors.muted,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      Color color, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withOpacity(0.8)),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: color, size: 18)
            : null,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3.  ASSIGN QUEST SHEET — pick athletes to assign a quest to
// ══════════════════════════════════════════════════════════════════════════════
class _AssignQuestSheet extends StatefulWidget {
  final Map<String, dynamic>    quest;
  final List<dynamic>           athletes;
  final Map<String, dynamic>    userData;
  final String                  password;
  final VoidCallback            onAssigned;

  const _AssignQuestSheet({
    required this.quest,
    required this.athletes,
    required this.userData,
    required this.password,
    required this.onAssigned,
  });

  @override
  State<_AssignQuestSheet> createState() => _AssignQuestSheetState();
}

class _AssignQuestSheetState extends State<_AssignQuestSheet> {
  late Set<int> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final alreadyAssigned = (widget.quest['assigned_recruit_ids'] as List? ?? [])
        .map((e) => e as int)
        .toSet();
    _selected = alreadyAssigned;
  }

  void _save() async {
    setState(() => _saving = true);
    try {
      await QuestService.assignQuest(
          widget.userData['username'],
          widget.password,
          widget.quest['id'],
          _selected.toList());
      if (!mounted) return;
      Navigator.pop(context);
      widget.onAssigned();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Assigned to ${_selected.length} athlete(s)'),
          backgroundColor: FQColors.green));
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FQColors.border)),
      ),
      child: Column(children: [
        Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: FQColors.muted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('ASSIGN QUEST',
                style: GoogleFonts.rajdhani(
                    color: FQColors.purple,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const Spacer(),
            _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: FQColors.purple, strokeWidth: 2))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: FQColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        textStyle: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold)),
                    onPressed: _save,
                    child: const Text('SAVE')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(widget.quest['title'],
              style: const TextStyle(color: FQColors.muted, fontSize: 13)),
        ),
        const Divider(color: FQColors.border, height: 1),
        Expanded(
          child: widget.athletes.isEmpty
              ? Center(
                  child: Text('No athletes on your roster',
                      style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: widget.athletes.length,
                  itemBuilder: (_, i) {
                    final a = widget.athletes[i] as Map<String, dynamic>;
                    final id = a['id'] as int;
                    final checked = _selected.contains(id);
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: FQColors.purple.withOpacity(0.15),
                        child: Text(
                          a['username'].toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: FQColors.purple, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(a['username'],
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('Lv.${a['level'] ?? 1}',
                          style: const TextStyle(
                              color: FQColors.gold, fontSize: 11)),
                      trailing: Checkbox(
                        value: checked,
                        activeColor: FQColors.purple,
                        onChanged: (_) => setState(() {
                          if (checked) {
                            _selected.remove(id);
                          } else {
                            _selected.add(id);
                          }
                        }),
                      ),
                      onTap: () => setState(() {
                        if (checked) {
                          _selected.remove(id);
                        } else {
                          _selected.add(id);
                        }
                      }),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 4.  QUEST TILE — single quest card on the list
// ══════════════════════════════════════════════════════════════════════════════
class _QuestTile extends StatelessWidget {
  final Map<String, dynamic> quest;
  final VoidCallback onAssign;
  final VoidCallback onDelete;

  const _QuestTile(
      {required this.quest, required this.onAssign, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final diff     = quest['difficulty'] ?? 'MEDIUM';
    final diffColor = diff == 'EASY'
        ? FQColors.green
        : diff == 'HARD'
            ? FQColors.red
            : FQColors.gold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FQColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FQColors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.military_tech_outlined,
                  color: FQColors.purple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(quest['title'],
                    style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                if ((quest['description'] ?? '').isNotEmpty)
                  Text(quest['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: FQColors.muted, fontSize: 11)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: FQColors.muted, size: 18),
              onPressed: onDelete,
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _chip('${quest['xp_reward']} XP', FQColors.gold,
                Icons.bolt),
            const SizedBox(width: 6),
            _chip('${quest['coin_reward']} coins', FQColors.cyan,
                Icons.monetization_on_outlined),
            const SizedBox(width: 6),
            _chip(diff, diffColor, Icons.signal_cellular_alt),
            if (quest['is_community'] == true) ...[
              const SizedBox(width: 6),
              _chip('ALL ATHLETES', FQColors.purple, Icons.groups_outlined),
            ],
            const Spacer(),
            _chip('${quest['assigned_count']} assigned', FQColors.muted,
                Icons.group_outlined),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              onPressed: onAssign,
              child: const Text('ASSIGN TO ATHLETES'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// 5.  RECRUIT QUEST SCREEN — view assigned quests and mark them complete
// ══════════════════════════════════════════════════════════════════════════════
class RecruitQuestScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const RecruitQuestScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<RecruitQuestScreen> createState() => _RecruitQuestScreenState();
}

class _RecruitQuestScreenState extends State<RecruitQuestScreen> {
  List<dynamic> _quests       = [];
  List<dynamic> _todayMissions = [];
  bool          _loading      = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        QuestService.fetchMyAssignedQuests(
            widget.userData['username'], widget.password),
        QuestService.fetchTodayQuests(
            widget.userData['username'], widget.password)
            .catchError((_) => <dynamic>[]),
      ]);
      if (mounted) {
        setState(() {
          _quests        = results[0];
          _todayMissions = results[1];
          _loading       = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _loadQuests() => _loadAll();

  void _completeDaily(Map<String, dynamic> mission) async {
    try {
      final result = await QuestService.completeTodayQuest(
          widget.userData['username'],
          widget.password,
          mission['type'] as String,
          mission['source_id'] as int);
      if (!mounted) return;
      _loadAll();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: FQColors.surface,
          title: Row(children: [
            const Icon(Icons.today, color: FQColors.gold, size: 28),
            const SizedBox(width: 8),
            Text('MISSION COMPLETE!',
                style: GoogleFonts.rajdhani(
                    color: FQColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(mission['title'] as String? ?? '',
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _rewardChip('+${result['xp_reward']} XP',
                  FQColors.gold, Icons.bolt),
              const SizedBox(width: 12),
              _rewardChip('+${result['coin_reward']} coins',
                  FQColors.cyan, Icons.monetization_on_outlined),
            ]),
          ]),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.gold,
                  foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context),
              child: Text('AWESOME!',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: FQColors.red));
      }
    }
  }

  void _complete(Map<String, dynamic> quest) async {
    try {
      final result = await QuestService.completeQuest(
          widget.userData['username'], widget.password, quest['id']);
      if (!mounted) return;
      _loadQuests();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: FQColors.surface,
          title: Row(children: [
            const Icon(Icons.military_tech, color: FQColors.gold, size: 28),
            const SizedBox(width: 8),
            Text('QUEST COMPLETE!',
                style: GoogleFonts.rajdhani(
                    color: FQColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(quest['title'],
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _rewardChip('+${result['xp_reward']} XP', FQColors.gold, Icons.bolt),
              const SizedBox(width: 12),
              _rewardChip('+${result['coin_reward']} coins', FQColors.cyan,
                  Icons.monetization_on_outlined),
            ]),
          ]),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.gold, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context),
              child: Text('AWESOME!',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: FQColors.red));
      }
    }
  }

  Widget _rewardChip(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    // Filter today's missions: show only nutrition type here
    final nutritionMissions = _todayMissions
        .where((m) => (m['type'] as String? ?? '') == 'nutrition')
        .toList();
    // Split assigned quests by auto-generated flag
    final autoQuests   = _quests.where((q) => q['is_auto_generated'] == true).toList();
    final customQuests = _quests.where((q) => q['is_auto_generated'] != true).toList();

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: const Text('MY QUESTS'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadQuests)
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.purple))
          : CustomScrollView(
              slivers: [
                // TODAY'S NUTRITION GOAL section
                if (nutritionMissions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(children: [
                        const Icon(Icons.restaurant_menu, color: FQColors.green, size: 16),
                        const SizedBox(width: 6),
                        Text("TODAY'S NUTRITION GOAL",
                            style: GoogleFonts.rajdhani(
                                color: FQColors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                      ]),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final m = nutritionMissions[i] as Map<String, dynamic>;
                        final done = m['is_completed'] == true;
                        final mType = m['type'] as String? ?? 'nutrition';
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          decoration: BoxDecoration(
                            color: done
                                ? FQColors.green.withOpacity(0.05)
                                : FQColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: done
                                    ? FQColors.green.withOpacity(0.3)
                                    : FQColors.gold.withOpacity(0.4)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (done
                                          ? FQColors.green
                                          : FQColors.gold)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  done
                                      ? Icons.check_circle_outline
                                      : (mType == 'workout'
                                          ? Icons.fitness_center
                                          : Icons.restaurant_menu),
                                  color: done ? FQColors.green : FQColors.gold,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(m['title'] as String? ?? '',
                                      style: TextStyle(
                                          color: done
                                              ? FQColors.muted
                                              : Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                      m['description'] as String? ?? '',
                                      style: const TextStyle(
                                          color: FQColors.muted,
                                          fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    _miniChip(
                                        '+${m['xp_reward']} XP',
                                        FQColors.gold),
                                    const SizedBox(width: 6),
                                    _miniChip(
                                        '+${m['coin_reward']} coins',
                                        FQColors.cyan),
                                  ]),
                                ]),
                              ),
                              if (!done)
                                ElevatedButton(
                                  onPressed: () => _completeDaily(m),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FQColors.gold,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    textStyle: GoogleFonts.rajdhani(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  child: const Text('DONE'),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: FQColors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('DONE',
                                      style: TextStyle(
                                          color: FQColors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ]),
                          ),
                        );
                      },
                      childCount: nutritionMissions.length,
                    ),
                  ),
                ],

                // ASSIGNED QUESTS — AUTO-GENERATED (slim rows)
                if (autoQuests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome,
                            color: FQColors.cyan, size: 14),
                        const SizedBox(width: 6),
                        Text('TRAINING PLANS',
                            style: GoogleFonts.rajdhani(
                                color: FQColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                      ]),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final q = autoQuests[i] as Map<String, dynamic>;
                        final done = q['is_completed'] == true;
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: FQColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: done
                                    ? FQColors.green.withOpacity(0.3)
                                    : FQColors.border),
                          ),
                          child: Row(children: [
                            Icon(
                              done
                                  ? Icons.check_circle_outline
                                  : Icons.auto_awesome,
                              color: done ? FQColors.green : FQColors.cyan,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(q['title'] ?? '',
                                  style: TextStyle(
                                      color: done
                                          ? FQColors.muted
                                          : Colors.white,
                                      fontSize: 13,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null)),
                            ),
                            _miniChip(
                                '+${q['xp_reward']} XP', FQColors.gold),
                          ]),
                        );
                      },
                      childCount: autoQuests.length,
                    ),
                  ),
                ],

                // ASSIGNED QUESTS — CUSTOM (full cards)
                if (customQuests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(children: [
                        const Icon(Icons.military_tech_outlined,
                            color: FQColors.gold, size: 14),
                        const SizedBox(width: 6),
                        Text('CUSTOM QUESTS',
                            style: GoogleFonts.rajdhani(
                                color: FQColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final q = customQuests[i] as Map<String, dynamic>;
                          final done = q['is_completed'] == true;
                          final diff = q['difficulty'] ?? 'MEDIUM';
                          final diffColor = diff == 'EASY'
                              ? FQColors.green
                              : diff == 'HARD'
                                  ? FQColors.red
                                  : FQColors.gold;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: done
                                  ? FQColors.green.withOpacity(0.05)
                                  : FQColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: done
                                      ? FQColors.green.withOpacity(0.3)
                                      : FQColors.gold.withOpacity(0.4)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (done
                                              ? FQColors.green
                                              : FQColors.gold)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      done
                                          ? Icons.check_circle_outline
                                          : Icons.military_tech_outlined,
                                      color: done ? FQColors.green : FQColors.gold,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(q['title'],
                                        style: TextStyle(
                                            color: done
                                                ? FQColors.muted
                                                : Colors.white,
                                            fontWeight: FontWeight.w600,
                                            decoration: done
                                                ? TextDecoration.lineThrough
                                                : null)),
                                  ),
                                ]),
                                if ((q['description'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(q['description'],
                                      style: const TextStyle(
                                          color: FQColors.muted, fontSize: 12)),
                                ],
                                const SizedBox(height: 10),
                                Row(children: [
                                  _miniChip(
                                      '+${q['xp_reward']} XP', FQColors.gold),
                                  const SizedBox(width: 6),
                                  _miniChip(
                                      '+${q['coin_reward']} coins', FQColors.cyan),
                                  const SizedBox(width: 6),
                                  _miniChip(diff, diffColor),
                                  const Spacer(),
                                  if (!done)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: FQColors.gold,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        textStyle: GoogleFonts.rajdhani(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _complete(q),
                                      child: const Text('COMPLETE'),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: FQColors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('DONE',
                                          style: TextStyle(
                                              color: FQColors.green,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ]),
                              ]),
                            ),
                          );
                        },
                        childCount: customQuests.length,
                      ),
                    ),
                  ),
                ],

                if (_quests.isEmpty && _todayMissions.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.military_tech_outlined,
                            size: 56,
                            color: FQColors.muted.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('No quests assigned yet',
                            style: GoogleFonts.rajdhani(
                                color: FQColors.muted, fontSize: 18)),
                        const SizedBox(height: 6),
                        const Text('Your coach will assign challenges soon',
                            style: TextStyle(
                                color: FQColors.muted, fontSize: 12)),
                      ]),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _miniChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10)),
      );
}
