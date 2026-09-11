import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
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
      final users = await ApiService.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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
      appBar: AppBar(title: const Text('Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _users.length,
                    itemBuilder: (context, i) {
                      final u = _users[i];
                      final banned = u['is_banned'] == 1 || u['is_banned'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: banned ? Colors.redAccent.withOpacity(0.5) : AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(
                            children: [
                              Expanded(child: Text(u['email'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              if (banned) const Chip(label: Text('Banned', style: TextStyle(fontSize: 10, color: Colors.redAccent)), backgroundColor: Color(0x33FF5252)),
                            ],
                          ),
                          subtitle: Text('Balance: LKR ${u['wallet_balance']}  ·  Verified: ${u['verified_status']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(userId: u['id'])));
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class UserDetailScreen extends StatefulWidget {
  final int userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;
  bool _editing = false;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

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
      final data = await ApiService.getUserDetail(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = data;
        _nameCtrl.text = data['displayName'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateUser(
        widget.userId,
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      setState(() => _editing = false);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _banUser() async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Ban User', style: TextStyle(color: Colors.white)),
        content: TextField(controller: reasonCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Reason for ban')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), child: const Text('Ban')),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await ApiService.banUser(widget.userId, reason.isEmpty ? 'Violation of terms' : reason);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _unbanUser() async {
    try {
      await ApiService.unbanUser(widget.userId);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _adjustWallet() async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Adjust Wallet', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Amount (+ or -)')),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Reason (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply')),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null) return;
    try {
      await ApiService.adjustWallet(widget.userId, amount, reasonCtrl.text.trim());
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text('Permanently delete this account? This cannot be undone.', style: TextStyle(color: AppColors.hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteUser(widget.userId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    final banned = u?['isBanned'] == true;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          if (!_loading && u != null)
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              onPressed: () => setState(() => _editing = !_editing),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (banned)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Chip(label: Text('BANNED', style: TextStyle(color: Colors.redAccent, fontSize: 11)), backgroundColor: Color(0x33FF5252)),
                            ),
                          const Text('Display Name', style: TextStyle(color: AppColors.hint, fontSize: 11)),
                          const SizedBox(height: 4),
                          _editing
                              ? TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(isDense: true))
                              : Text(u?['displayName'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          const Text('Email', style: TextStyle(color: AppColors.hint, fontSize: 11)),
                          const SizedBox(height: 4),
                          _editing
                              ? TextField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(isDense: true))
                              : Text(u?['email'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 14),
                          const Text('Phone', style: TextStyle(color: AppColors.hint, fontSize: 11)),
                          const SizedBox(height: 4),
                          _editing
                              ? TextField(controller: _phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(isDense: true))
                              : Text(u?['phone'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          if (_editing) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statRow('Wallet Balance', 'LKR ${u?['walletBalance']}'),
                          _statRow('Referral Points', '${u?['referralPoints']} pts'),
                          _statRow('Verified Status', u?['verifiedStatus'] ?? ''),
                          _statRow('Auth Provider', u?['authProvider'] ?? ''),
                          _statRow('Listings', '${u?['listingsCount']}'),
                          _statRow('Orders', '${u?['ordersCount']}'),
                          _statRow('Joined', (u?['createdAt'] ?? '').toString().substring(0, 10)),
                          if (u?['bankName'] != null) ...[
                            const Divider(color: AppColors.border, height: 20),
                            _statRow('Bank', '${u?['bankName']} · ${u?['bankAccountName']}'),
                            _statRow('Account No.', '${u?['bankAccountNumber']}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(onPressed: _adjustWallet, child: const Text('Adjust Wallet')),
                        if (banned)
                          OutlinedButton(onPressed: _unbanUser, child: const Text('Unban'))
                        else
                          OutlinedButton(
                            onPressed: _banUser,
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
                            child: const Text('Ban', style: TextStyle(color: Colors.orangeAccent)),
                          ),
                        OutlinedButton(
                          onPressed: _deleteUser,
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                          child: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
