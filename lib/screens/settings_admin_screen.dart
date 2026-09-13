import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'users_screen.dart';
import 'promotions_admin_screen.dart';
import 'sub_admin_management_screen.dart';
import 'content_reports_screen.dart';

const String kAppVersion = '1.0.1';

class SettingsAdminScreen extends StatefulWidget {
  const SettingsAdminScreen({super.key});

  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  final _commissionCtrl = TextEditingController();
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastBodyCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  bool _loading = true;
  bool _savingCommission = false;
  bool _sendingBroadcast = false;
  bool _savingBankDetails = false;
  String? _commissionMsg;
  String? _broadcastMsg;
  String? _bankDetailsMsg;

  @override
  void initState() {
    super.initState();
    _loadCommission();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    try {
      final details = await ApiService.getAdminBankDetails();
      if (!mounted) return;
      setState(() {
        _bankNameCtrl.text = details['bankName'] ?? '';
        _accountNameCtrl.text = details['accountName'] ?? '';
        _accountNumberCtrl.text = details['accountNumber'] ?? '';
        _branchCtrl.text = details['branch'] ?? '';
      });
    } catch (_) {}
  }

  Future<void> _saveBankDetails() async {
    if (_bankNameCtrl.text.trim().isEmpty ||
        _accountNameCtrl.text.trim().isEmpty ||
        _accountNumberCtrl.text.trim().isEmpty ||
        _branchCtrl.text.trim().isEmpty) {
      setState(() => _bankDetailsMsg = 'All fields are required');
      return;
    }
    setState(() {
      _savingBankDetails = true;
      _bankDetailsMsg = null;
    });
    try {
      await ApiService.updateAdminBankDetails(
        _bankNameCtrl.text.trim(),
        _accountNameCtrl.text.trim(),
        _accountNumberCtrl.text.trim(),
        _branchCtrl.text.trim(),
      );
      setState(() => _bankDetailsMsg = 'Bank details updated successfully');
    } catch (e) {
      setState(() => _bankDetailsMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingBankDetails = false);
    }
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

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> submit() async {
            if (newCtrl.text.trim().length < 6) {
              setDialogState(() => errorMsg = 'New password must be at least 6 characters');
              return;
            }
            if (newCtrl.text.trim() != confirmCtrl.text.trim()) {
              setDialogState(() => errorMsg = 'Passwords do not match');
              return;
            }
            setDialogState(() {
              saving = true;
              errorMsg = null;
            });
            try {
              await ApiService.changePassword(currentCtrl.text.trim(), newCtrl.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            } catch (e) {
              setDialogState(() {
                saving = false;
                errorMsg = e.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Change Password', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Current Password'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Confirm New Password'),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: saving ? null : submit,
                child: saving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Text('Checking for updates...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final result = await ApiService.checkForUpdate(kAppVersion);
      if (!mounted) return;
      Navigator.pop(context);

      if (result['updateAvailable'] == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Update Available', style: TextStyle(color: Colors.white)),
            content: Text(
              'Version ${result['latestVersion']} is available.\n\n${result['releaseNotes'] ?? ''}',
              style: const TextStyle(color: AppColors.hint, fontSize: 13),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
              if (result['downloadUrl'] != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _downloadAndInstallUpdate(result['downloadUrl']);
                  },
                  child: const Text('Download'),
                ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're on the latest version")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _downloadAndInstallUpdate(String url) async {
    double progress = 0;
    void Function(void Function())? refreshDialog;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            refreshDialog = setDialogState;
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Downloading Update', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    progress > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : 'Starting download...',
                    style: const TextStyle(color: AppColors.hint, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please keep the app open until the download completes.',
                    style: TextStyle(color: AppColors.hint, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/admin-app-release.apk';

      await Dio().download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            progress = received / total;
            refreshDialog?.call(() {});
          }
        },
      );

      if (mounted) Navigator.pop(context);
      await OpenFilex.open(filePath);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
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
          _tile(Icons.admin_panel_settings_outlined, 'Sub-Admins', 'Requests, devices, email, reports', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubAdminManagementScreen()));
          }),
          _tile(Icons.flag_outlined, 'Reported Content', 'Listings and users reported by customers', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentReportsScreen()));
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
          const Text('Top-Up Bank Details', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Shown to users when they top up their wallet', style: TextStyle(color: AppColors.hint, fontSize: 11)),
          const SizedBox(height: 10),
          TextField(
            controller: _bankNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Bank Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _accountNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Account Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _accountNumberCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Account Number'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _branchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Branch'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _savingBankDetails ? null : _saveBankDetails,
              child: _savingBankDetails
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update Bank Details'),
            ),
          ),
          if (_bankDetailsMsg != null) ...[
            const SizedBox(height: 6),
            Text(_bankDetailsMsg!, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
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

          const SizedBox(height: 24),
          const Text('Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          _tile(Icons.lock_reset, 'Change Password', 'Update your admin login password', _showChangePasswordDialog),
          _tile(Icons.info_outline, 'App Version', '$kAppVersion — Tap to check for updates', _checkForUpdate),

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
