import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/profile_controller.dart';
import '../../../model/profile_model.dart';
import '../../../service/supabase_conn.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});
  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  bool _editing = false;
  bool _saving  = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  String? _dob;
  String? _gender;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileController>().profile;
    _nameCtrl    = TextEditingController(text: profile?.fullName ?? '');
    _emailCtrl   = TextEditingController(text: supabase.auth.currentUser?.email ?? '');
    _phoneCtrl   = TextEditingController(text: profile?.phone ?? '');
    _addressCtrl = TextEditingController();
    _dob         = null; // stored separately
    _gender      = profile?.gender;
    _heightCtrl  = TextEditingController(text: profile?.heightCm?.toStringAsFixed(0) ?? '');
    _weightCtrl  = TextEditingController(text: profile?.weightKg?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ctrl    = context.read<ProfileController>();
    final profile = ctrl.profile;
    final uid     = supabase.auth.currentUser!.id;
    final hCm     = double.tryParse(_heightCtrl.text) ?? profile?.heightCm;
    final wKg     = double.tryParse(_weightCtrl.text) ?? profile?.weightKg;
    final newBmi  = (hCm != null && wKg != null)
        ? wKg / ((hCm / 100) * (hCm / 100))
        : profile?.bmi;

    await ctrl.updateProfile(ProfileModel(
      id:              profile?.id,
      userId:          uid,
      fullName:        _nameCtrl.text.trim(),
      phone:           _phoneCtrl.text.trim(),
      heightCm:        hCm,
      weightKg:        wKg,
      age:             profile?.age,
      gender:          _gender ?? profile?.gender,
      activityLevel:   profile?.activityLevel,
      bmi:             newBmi,
      dailyCalorieGoal: profile?.dailyCalorieGoal,
      proteinGoalG:    profile?.proteinGoalG,
      carbsGoalG:      profile?.carbsGoalG,
      fatGoalG:        profile?.fatGoalG,
    ));

    if (mounted) setState(() { _saving = false; _editing = false; });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            if (_editing) setState(() => _editing = false);
            else Navigator.pop(context);
          },
          child: Text(_editing ? 'Cancel' : '', style: const TextStyle(color: _green, fontWeight: FontWeight.w600)),
        ),
        title: const Text('My Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _editing ? (_saving ? null : _save) : () => setState(() => _editing = true),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _orange))
                : Text(_editing ? 'Save' : 'Edit', style: const TextStyle(color: _orange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: _green.withValues(alpha: 0.15),
                child: Icon(Icons.person, size: 44, color: _green.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Fields ──────────────────────────────────────────────────────
            _field('Full Name',  _nameCtrl,  enabled: _editing),
            _field('Email',      _emailCtrl, enabled: false),
            _field('Phone',      _phoneCtrl, enabled: _editing, prefix: '+60 '),
            _field('Address',    _addressCtrl, enabled: _editing),

            // DOB row
            _readRow('Date of Birth', profile?.age != null ? '-- / -- / ----' : 'Not set'),
            // Gender
            _genderRow(),
            _field('Height (cm)', _heightCtrl, enabled: _editing, keyboardType: TextInputType.number),
            _field('Weight (kg)', _weightCtrl, enabled: _editing, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool enabled = true,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: _dark),
            decoration: InputDecoration(
              prefixText: prefix,
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF8F6F2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _dark.withValues(alpha: 0.12))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _dark.withValues(alpha: 0.12))),
              disabledBorder:OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _dark.withValues(alpha: 0.08))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _orange, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _dark.withValues(alpha: 0.08)),
            ),
            child: Text(value, style: TextStyle(fontSize: 14, color: _dark.withValues(alpha: 0.6))),
          ),
        ],
      ),
    );
  }

  Widget _genderRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gender', style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female'].map((g) {
              final sel = _gender == g;
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: _editing ? () => setState(() => _gender = g) : null,
                  child: Row(
                    children: [
                      Icon(
                        sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: sel ? _green : _dark.withValues(alpha: 0.4),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(g, style: const TextStyle(fontSize: 14, color: _dark)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
