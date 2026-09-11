import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      final items = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      ApiService.markAllNotificationsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  IconData _iconFor(String type) {
    if (type.contains('verification')) return Icons.verified_outlined;
    if (type.contains('support') || type.contains('chat')) return Icons.support_agent_outlined;
    if (type.contains('sub_admin')) return Icons.admin_panel_settings_outlined;
    if (type.contains('device')) return Icons.phonelink_lock_outlined;
    if (type.contains('email')) return Icons.email_outlined;
    if (type.contains('report')) return Icons.flag_outlined;
    if (type.contains('dispute')) return Icons.gavel_outlined;
    if (type.contains('withdraw') || type.contains('topup') || type.contains('wallet')) return Icons.account_balance_wallet_outlined;
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _items.isEmpty
                  ? const Center(child: Text('No notifications yet', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final n = _items[i];
                          final isRead = n['isRead'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isRead ? AppColors.surface : AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(_iconFor(n['type'] ?? ''), color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(n['body'] ?? '', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                      const SizedBox(height: 6),
                                      Text((n['createdAt'] ?? '').toString().substring(0, 16), style: const TextStyle(color: AppColors.hint, fontSize: 10)),
                                    ],
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
