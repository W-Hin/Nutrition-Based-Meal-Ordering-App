import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../service/supabase_conn.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _saving         = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newPass     = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack('Please fill in both fields.', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnack('Password must be at least 6 characters.', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to update password. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 18),
              const Text(
                'Password changed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark),
              ),
              const SizedBox(height: 8),
              Text(
                'Congratulations! Your password has been updated.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.6), height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Go back', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _passField('New Password *', _newPassCtrl, _obscureNew, () {
              setState(() => _obscureNew = !_obscureNew);
            }),
            const SizedBox(height: 16),
            _passField('Confirm Password *', _confirmPassCtrl, _obscureConfirm, () {
              setState(() => _obscureConfirm = !_obscureConfirm);
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.55), fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14, color: _dark),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: _dark.withValues(alpha: 0.4)),
              onPressed: toggle,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _dark.withValues(alpha: 0.12))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _dark.withValues(alpha: 0.12))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _orange, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
