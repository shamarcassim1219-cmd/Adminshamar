import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'users_screen.dart';
import 'promotions_admin_screen.dart';

class SettingsAdminScreen extends StatefulWidget {
  const SettingsAdminScreen({super.key});

  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  final _commissionCtrl = TextEditingController();
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastBodyCtrl = TextEditingController();
  bool _loading = true;
  bool _savingCommission = false;
  bool _sendingBroadcast = false;
  String? _commissionMsg;
  String? _broadcastMsg;

  @override
  void initState() {
    super.initState();
    _loadCommission();
  }

  Future<void> _loadCommission() async {
    try {
      final rate = await ApiService.getCommissionRate();
      if (!mounted) return;
      setState(() {
        _commissionCtrl.text = (rate * 100).toStringAsFixed(1);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCommission() async {
    final val = double.tryParse(_commissionCtrl.text.trim());
    if (val == null) return;
    setState(() {
      _savingCommission = true;
      _commissionMsg = null;
    });
    try {
      await ApiService.setCommissionRate(val / 100);
      setState(() => _commissionMsg = 'Commission updated to ${val.toStringAsFixed(1)}%');
    } catch (e) {
      setState(() => _commissionMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingCommission = false);
    }
  }

  Future<void> _sendBroadcast() async {
    if (_broadcastTitleCtrl.text.trim().isEmpty || _broadcastBodyCtrl.text.trim().isEmpty) return;
    setState(() {
      _sendingBroadcast = true;
      _broadcastMsg = null;
    });
    try {
      await ApiService.broadcast(_broadcastTitleCtrl.text.trim(), _broadcastBodyCtrl.text.trim());
      _broadcastTitleCtrl.clear();
      _broadcastBodyCtrl.clear();
      setState(() => _broadcastMsg = 'Notification sent to all users');
    } catch (e) {
      setState(() => _broadcastMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingBroadcast = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(Icons.people_outline, 'Users', 'Ban, unban, adjust wallets', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
          }),
          _tile(Icons.campaign_outlined, 'Promotions', 'Post and manage ads', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PromotionsAdminScreen()));
          }),

          const SizedBox(height: 20),
          const Text('Platform Commission', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary)))
          else ...[
            TextField(
              controller: _commissionCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Commission Rate (%)'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _savingCommission ? null : _saveCommission,
                child: _savingCommission
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update Commission'),
              ),
            ),
            if (_commissionMsg != null) ...[
              const SizedBox(height: 6),
              Text(_commissionMsg!, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
            ],
          ],

          const SizedBox(height: 24),
          const Text('Send Promotion Notification', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          TextField(controller: _broadcastTitleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: _broadcastBodyCtrl, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _sendingBroadcast ? null : _sendBroadcast,
              child: _sendingBroadcast
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send to All Users'),
            ),
          ),
          if (_broadcastMsg != null) ...[
            const SizedBox(height: 6),
            Text(_broadcastMsg!, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
          ],

          const SizedBox(height: 30),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Logout')),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.hint),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
        onTap: onTap,
      ),
    );
  }
}
