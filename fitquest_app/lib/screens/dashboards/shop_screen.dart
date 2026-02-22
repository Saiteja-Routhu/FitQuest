import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/shop_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 1.  SHOP SCREEN — Coach's reward shop
// ══════════════════════════════════════════════════════════════════════════════
class ShopScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const ShopScreen({super.key, required this.userData, required this.password});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _items     = [];
  List<dynamic> _purchases = [];
  bool          _loading   = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _loadAll() async {
    try {
      final results = await Future.wait([
        ShopService.fetchMyShopItems(widget.userData['username'], widget.password),
        ShopService.fetchPurchases(widget.userData['username'], widget.password),
      ]);
      if (mounted) {
        setState(() {
          _items     = results[0];
          _purchases = results[1];
          _loading   = false;
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

  void _showAddDialog() async {
    final nameCtrl  = TextEditingController();
    final descCtrl  = TextEditingController();
    final priceCtrl = TextEditingController(text: '50');
    bool  isSaving  = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setDs) {
        return AlertDialog(
          backgroundColor: FQColors.surface,
          title: Text('ADD SHOP ITEM',
              style: GoogleFonts.rajdhani(
                  color: FQColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _dlgField(nameCtrl, 'Item Name', Icons.storefront_outlined),
            const SizedBox(height: 12),
            _dlgField(descCtrl, 'Description (optional)',
                Icons.description_outlined, maxLines: 2),
            const SizedBox(height: 12),
            _dlgField(priceCtrl, 'Coin Price', Icons.monetization_on_outlined,
                isNumber: true),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL',
                    style: TextStyle(color: FQColors.muted))),
            isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: FQColors.gold, strokeWidth: 2))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: FQColors.gold,
                        foregroundColor: Colors.black),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setDs(() => isSaving = true);
                      try {
                        await ShopService.createShopItem(
                            widget.userData['username'], widget.password, {
                          'name':       nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'coin_price': int.tryParse(priceCtrl.text) ?? 50,
                        });
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDs(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: FQColors.red));
                        }
                      }
                    },
                    child: const Text('ADD')),
          ],
        );
      }),
    );

    if (saved == true) _loadAll();
  }

  void _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        title: const Text('Delete Item',
            style: TextStyle(color: Colors.white)),
        content: Text('Delete "${item['name']}"?',
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
      await ShopService.deleteShopItem(
          widget.userData['username'], widget.password, item['id']);
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _fulfillPurchase(Map<String, dynamic> purchase) async {
    try {
      await ShopService.fulfillPurchase(
          widget.userData['username'], widget.password, purchase['id']);
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Marked as fulfilled'),
            backgroundColor: FQColors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: const Text('THE SHOP'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll)
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: FQColors.gold,
          labelColor: FQColors.gold,
          unselectedLabelColor: FQColors.muted,
          labelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(text: 'ITEMS'),
            Tab(text: 'PURCHASES'),
          ],
        ),
      ),
      floatingActionButton: TabBuilder(
        controller: _tabs,
        builder: (index) => index == 0
            ? FloatingActionButton.extended(
                onPressed: _showAddDialog,
                backgroundColor: FQColors.gold,
                icon: const Icon(Icons.add, color: Colors.black),
                label: Text('ADD ITEM',
                    style: GoogleFonts.rajdhani(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              )
            : const SizedBox.shrink(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.gold))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildItemsList(),
                _buildPurchasesList(),
              ],
            ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.storefront_outlined,
              size: 56, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No items yet',
              style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Tap "ADD ITEM" to create rewards for athletes',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _items.length,
      itemBuilder: (_, i) => _ShopItemCard(
        item: _items[i],
        onDelete: () => _deleteItem(_items[i]),
      ),
    );
  }

  Widget _buildPurchasesList() {
    if (_purchases.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No purchases yet',
              style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 18)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _purchases.length,
      itemBuilder: (_, i) {
        final p        = _purchases[i] as Map<String, dynamic>;
        final fulfilled = p['is_fulfilled'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: fulfilled
                ? FQColors.green.withOpacity(0.04)
                : FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: fulfilled
                    ? FQColors.green.withOpacity(0.25)
                    : FQColors.border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: FQColors.gold.withOpacity(0.12),
              child: Text(
                (p['recruit_name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: FQColors.gold, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(p['item_name'] ?? '',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${p['recruit_name']} · ${p['coin_price']} coins',
              style: const TextStyle(color: FQColors.muted, fontSize: 11),
            ),
            trailing: fulfilled
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FQColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('DONE',
                        style: TextStyle(
                            color: FQColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FQColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    onPressed: () => _fulfillPurchase(p),
                    child: const Text('FULFILL'),
                  ),
          ),
        );
      },
    );
  }

  Widget _dlgField(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1
            ? Icon(icon, color: FQColors.muted, size: 16)
            : null,
      ),
    );
  }
}

// ── Tab-aware FAB helper ──────────────────────────────────────────────────────
class TabBuilder extends StatefulWidget {
  final TabController controller;
  final Widget Function(int index) builder;
  const TabBuilder(
      {super.key, required this.controller, required this.builder});

  @override
  State<TabBuilder> createState() => _TabBuilderState();
}

class _TabBuilderState extends State<TabBuilder> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChange);
  }

  void _onTabChange() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(widget.controller.index);
}

// ══════════════════════════════════════════════════════════════════════════════
// 2.  SHOP ITEM CARD
// ══════════════════════════════════════════════════════════════════════════════
class _ShopItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _ShopItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final purchaseCount = item['purchase_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FQColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FQColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: FQColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['name'],
                  style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              if ((item['description'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: FQColors.muted, fontSize: 11)),
              ],
              const SizedBox(height: 6),
              Row(children: [
                _chip('${item['coin_price']} coins', FQColors.gold,
                    Icons.monetization_on_outlined),
                const SizedBox(width: 6),
                _chip('$purchaseCount purchased', FQColors.cyan,
                    Icons.shopping_bag_outlined),
              ]),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: FQColors.muted, size: 18),
            onPressed: onDelete,
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
// 3.  RECRUIT SHOP SCREEN — browse and purchase items
// ══════════════════════════════════════════════════════════════════════════════
class RecruitShopScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const RecruitShopScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<RecruitShopScreen> createState() => _RecruitShopScreenState();
}

class _RecruitShopScreenState extends State<RecruitShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _items     = [];
  List<dynamic> _purchases = [];
  bool          _loading   = true;
  int           _coins     = 0;

  @override
  void initState() {
    super.initState();
    _tabs  = TabController(length: 2, vsync: this);
    _coins = widget.userData['coins'] ?? 0;
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _loadAll() async {
    try {
      final results = await Future.wait([
        ShopService.fetchAvailableItems(
            widget.userData['username'], widget.password),
        ShopService.fetchMyPurchases(
            widget.userData['username'], widget.password),
      ]);
      if (mounted) {
        setState(() {
          _items     = results[0];
          _purchases = results[1];
          _loading   = false;
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

  void _purchase(Map<String, dynamic> item) async {
    final price = item['coin_price'] as int;
    if (_coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Not enough coins! You have $_coins, need $price'),
          backgroundColor: FQColors.red));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        title: Text('Purchase Item',
            style: GoogleFonts.rajdhani(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(item['name'],
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          if ((item['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item['description'],
                style: const TextStyle(color: FQColors.muted, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.monetization_on_outlined,
                color: FQColors.gold, size: 20),
            const SizedBox(width: 4),
            Text('$price coins',
                style: const TextStyle(
                    color: FQColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ]),
          const SizedBox(height: 4),
          Text('Balance after: ${_coins - price} coins',
              style: const TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: FQColors.muted))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.gold,
                  foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context, true),
              child: Text('BUY',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ShopService.purchaseItem(
          widget.userData['username'], widget.password, item['id']);
      if (!mounted) return;
      setState(() => _coins = result['new_coins'] ?? _coins - price);
      _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Purchased ${item['name']}! 🎉'),
          backgroundColor: FQColors.green));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: const Text('THE SHOP'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.monetization_on_outlined,
                  color: FQColors.gold, size: 18),
              const SizedBox(width: 4),
              Text('$_coins',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ]),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: FQColors.gold,
          labelColor: FQColors.gold,
          unselectedLabelColor: FQColors.muted,
          labelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(text: 'AVAILABLE'),
            Tab(text: 'MY PURCHASES'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.gold))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildAvailableList(),
                _buildPurchaseHistory(),
              ],
            ),
    );
  }

  Widget _buildAvailableList() {
    if (_items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.storefront_outlined,
              size: 56, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Shop is empty',
              style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Your coach hasn\'t added any items yet',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final item  = _items[i] as Map<String, dynamic>;
        final price = item['coin_price'] as int;
        final canAfford = _coins >= price;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: canAfford
                    ? FQColors.gold.withOpacity(0.25)
                    : FQColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (canAfford ? FQColors.gold : FQColors.muted)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.storefront_outlined,
                    color: canAfford ? FQColors.gold : FQColors.muted,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['name'],
                      style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  if ((item['description'] ?? '').isNotEmpty)
                    Text(item['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: FQColors.muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.monetization_on_outlined,
                        color: FQColors.gold, size: 12),
                    const SizedBox(width: 3),
                    Text('$price coins',
                        style: const TextStyle(
                            color: FQColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ]),
                ]),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canAfford ? FQColors.gold : FQColors.surface,
                  foregroundColor:
                      canAfford ? Colors.black : FQColors.muted,
                  side: canAfford
                      ? null
                      : const BorderSide(color: FQColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                ),
                onPressed: canAfford ? () => _purchase(item) : null,
                child: const Text('BUY'),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildPurchaseHistory() {
    if (_purchases.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No purchases yet',
              style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 18)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _purchases.length,
      itemBuilder: (_, i) {
        final p         = _purchases[i] as Map<String, dynamic>;
        final fulfilled = p['is_fulfilled'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: fulfilled
                ? FQColors.green.withOpacity(0.04)
                : FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: fulfilled
                    ? FQColors.green.withOpacity(0.25)
                    : FQColors.border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (fulfilled ? FQColors.green : FQColors.gold)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                fulfilled
                    ? Icons.check_circle_outline
                    : Icons.storefront_outlined,
                color: fulfilled ? FQColors.green : FQColors.gold,
                size: 20,
              ),
            ),
            title: Text(p['item_name'] ?? '',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('${p['coin_price']} coins spent',
                style: const TextStyle(
                    color: FQColors.muted, fontSize: 11)),
            trailing: fulfilled
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FQColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('FULFILLED',
                        style: TextStyle(
                            color: FQColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FQColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('PENDING',
                        style: TextStyle(
                            color: FQColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
          ),
        );
      },
    );
  }
}
