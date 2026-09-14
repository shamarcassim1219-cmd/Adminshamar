import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ContentReportsScreen extends StatefulWidget {
  const ContentReportsScreen({super.key});

  @override
  State<ContentReportsScreen> createState() => _ContentReportsScreenState();
}

class _ContentReportsScreenState extends State<ContentReportsScreen> {
  List<dynamic> _items = [];
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
      final items = await ApiService.getContentReports();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _resolve(int id) async {
    try {
      await ApiService.resolveContentReport(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _resolveProblem(int id) async {
    try {
      await ApiService.resolveProblemReport(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _showBanDialog(int userId, String userLabel) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Ban $userLabel', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Reason for ban (sent to the user)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ban User'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonCtrl.text.trim().isEmpty ? 'Violation of terms' : reasonCtrl.text.trim();
      try {
        await ApiService.banUser(userId, reason);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User banned')));
        _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _unban(int userId) async {
    try {
      await ApiService.unbanUser(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unbanned')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Widget _personCard(String role, Map<String, dynamic>? person, {String? extraLabel}) {
    if (person == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8)),
        child: Text('$role: not found', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
      );
    }

    final int userId = person['id'] is int ? person['id'] : int.tryParse(person['id'].toString()) ?? 0;
    final bool isBanned = person['is_banned'] == true || person['is_banned'] == 1;
    final name = person['display_name'] ?? person['email'] ?? 'User #$userId';

    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(8),
        border: isBanned ? Border.all(color: Colors.redAccent.withOpacity(0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(role, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              if (extraLabel != null) ...[
                const SizedBox(width: 6),
                Text('($extraLabel)', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
              ],
              if (isBanned) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('BANNED', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          if (person['email'] != null) Text(person['email'], style: const TextStyle(color: AppColors.hint, fontSize: 11)),
          if (person['phone'] != null && person['phone'].toString().isNotEmpty) Text('Phone: ${person['phone']}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
          Text('Wallet: Rs. ${person['wallet_balance'] ?? 0}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
          Text('Verified: ${person['verified_status'] ?? 'unverified'}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
          if (isBanned && person['ban_reason'] != null)
            Text('Ban reason: ${person['ban_reason']}', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: isBanned
                ? OutlinedButton(onPressed: () => _unban(userId), child: const Text('Unban'))
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                    onPressed: () => _showBanDialog(userId, name),
                    child: const Text('Ban This User'),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Reported Content')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _items.isEmpty
                  ? const Center(child: Text('No open reports', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final r = _items[i];

                          if (r['type'] == 'problem') {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.report_problem_outlined, size: 16, color: AppColors.primary),
                                      SizedBox(width: 6),
                                      Text('Problem Report', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(r['reporter_name'] ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (r['reporter_email'] != null) Text(r['reporter_email'], style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                  if (r['reporter_phone'] != null && r['reporter_phone'].toString().isNotEmpty)
                                    Text('Phone: ${r['reporter_phone']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8)),
                                    child: Text(r['description'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(onPressed: () => _resolveProblem(r['id']), child: const Text('Mark Resolved')),
                                  ),
                                ],
                              ),
                            );
                          }

                          final isListing = r['target_type'] == 'listing';
                          final reporter = r['reporter_details'] as Map<String, dynamic>?;
                          final targetUser = r['target_user_details'] as Map<String, dynamic>?;
                          final targetListing = r['target_listing'] as Map<String, dynamic>?;
                          final listingStatusLabel = targetListing != null ? targetListing['status']?.toString() : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(isListing ? Icons.storefront_outlined : Icons.person_outline, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(isListing ? 'Listing Report' : 'User Report', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(r['target_label'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Reason: ${r['reason'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                if ((r['details'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8)),
                                    child: Text(r['details'], style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                  ),
                                ],
                                const Divider(height: 20),
                                _personCard('REPORTED BY', reporter),
                                _personCard(
                                  isListing ? 'LISTING SELLER' : 'REPORTED USER',
                                  targetUser,
                                  extraLabel: isListing ? listingStatusLabel : null,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(onPressed: () => _resolve(r['id']), child: const Text('Mark Resolved')),
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
