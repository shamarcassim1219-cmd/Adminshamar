import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await ApiService.getPendingOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Pending Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _orders.isEmpty
                  ? const Center(child: Text('No orders pending review', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (context, i) {
                          final o = _orders[i];
                          final screenshots = (o['screenshots'] as List?) ?? [];
                          final deadline = o['reviewDeadline'] != null ? DateTime.parse(o['reviewDeadline']) : null;
                          final overdue = deadline != null && deadline.isBefore(DateTime.now());
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: overdue ? Colors.redAccent.withOpacity(0.5) : AppColors.border),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: screenshots.isNotEmpty
                                        ? Image.network(screenshots[0], width: 56, height: 56, fit: BoxFit.cover)
                                        : Container(width: 56, height: 56, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                                  ),
                                  title: Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    'LKR ${(o['price'] as num).toStringAsFixed(2)}\nBuyer: ${o['buyerEmail']}\nSeller: ${o['sellerEmail']}',
                                    style: const TextStyle(color: AppColors.hint, fontSize: 11),
                                  ),
                                  trailing: overdue
                                      ? const Chip(label: Text('Overdue', style: TextStyle(fontSize: 10, color: Colors.redAccent)), backgroundColor: Color(0x33FF5252))
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderReviewScreen(order: o)));
                                        _load();
                                      },
                                      child: const Text('Review Order'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class OrderReviewScreen extends StatefulWidget {
  final Map order;
  const OrderReviewScreen({super.key, required this.order});

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _recoveryCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _sharing = false;
  String? _error;
  String _chatType = 'admin_buyer';
  Map<String, int> _conversations = {};
  List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final vault = await ApiService.getOrderVault(widget.order['id']);
      _emailCtrl.text = vault['email'] ?? '';
      _passwordCtrl.text = vault['password'] ?? '';
      _recoveryCtrl.text = vault['recoveryCodes'] ?? '';

      final convs = await ApiService.getOrderConversations(widget.order['id']);
      for (final c in convs) {
        _conversations[c['type']] = c['id'];
      }

      if (mounted) setState(() => _loading = false);
      _loadMessages();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    final convId = _conversations[_chatType];
    if (convId == null) return;
    try {
      final messages = await ApiService.getConversationMessages(convId);
      if (mounted) setState(() => _messages = messages);
    } catch (_) {}
  }

  Future<void> _saveVault() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateOrderVault(widget.order['id'], _emailCtrl.text, _passwordCtrl.text, _recoveryCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credentials updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Share Credentials', style: TextStyle(color: Colors.white)),
        content: const Text('Send these credentials to the buyer now?', style: TextStyle(color: AppColors.hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Share')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sharing = true);
    try {
      await ApiService.shareCredentials(widget.order['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credentials shared with buyer')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _sendMessage() async {
    final convId = _conversations[_chatType];
    if (convId == null || _msgCtrl.text.trim().isEmpty) return;
    try {
      await ApiService.sendConversationMessage(convId, _msgCtrl.text.trim());
      _msgCtrl.clear();
      _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Order #${widget.order['id']}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(widget.order['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Buyer: ${widget.order['buyerEmail']}  ·  Seller: ${widget.order['sellerEmail']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                    const SizedBox(height: 20),

                    const Text('Account Credentials', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    TextField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Account Email')),
                    const SizedBox(height: 12),
                    TextField(controller: _passwordCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Password')),
                    const SizedBox(height: 12),
                    TextField(controller: _recoveryCtrl, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Recovery Codes')),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : _saveVault,
                            child: _saving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sharing ? null : _share,
                            child: _sharing ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Share with Buyer'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text('Chat', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Buyer'),
                            selected: _chatType == 'admin_buyer',
                            onSelected: (_) {
                              setState(() {
                                _chatType = 'admin_buyer';
                                _messages = [];
                              });
                              _loadMessages();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Seller'),
                            selected: _chatType == 'admin_seller',
                            onSelected: (_) {
                              setState(() {
                                _chatType = 'admin_seller';
                                _messages = [];
                              });
                              _loadMessages();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: _messages.isEmpty
                          ? const Center(child: Text('No messages yet', style: TextStyle(color: AppColors.hint, fontSize: 12)))
                          : ListView.builder(
                              itemCount: _messages.length,
                              itemBuilder: (context, i) {
                                final m = _messages[i];
                                final isAdmin = m['isAdmin'] == true;
                                final isCred = m['isCredentialShare'] == true;
                                return Align(
                                  alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 3),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    constraints: const BoxConstraints(maxWidth: 260),
                                    decoration: BoxDecoration(
                                      color: isCred ? Colors.greenAccent.withOpacity(0.15) : (isAdmin ? AppColors.primary : AppColors.fieldFill),
                                      borderRadius: BorderRadius.circular(10),
                                      border: isCred ? Border.all(color: Colors.greenAccent) : null,
                                    ),
                                    child: Text(m['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(hintText: 'Type a message...'),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.send, color: AppColors.primary), onPressed: _sendMessage),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }
}
