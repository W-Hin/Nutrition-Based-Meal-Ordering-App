import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controller/profile_controller.dart';
import '../../../model/profile_model.dart';
import '../../../service/supabase_conn.dart';
import 'addresses_page.dart';

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

  // ── Text controllers ──────────────────────────────────────────────────────
  late TextEditingController _fullNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  // ── Pickers ───────────────────────────────────────────────────────────────
  DateTime? _dob;
  String?   _gender;

  // ── Default address label ─────────────────────────────────────────────────
  String _addressLabel = '';

  @override
  void initState() {
    super.initState();
    final ctrl    = context.read<ProfileController>();
    final profile = ctrl.profile;

    _fullNameCtrl = TextEditingController(
      text: [ctrl.firstName, ctrl.lastName]
          .where((p) => p.isNotEmpty)
          .join(' '),
    );
    _emailCtrl    = TextEditingController(text: supabase.auth.currentUser?.email ?? '');
    _phoneCtrl    = TextEditingController(text: ctrl.userPhone);
    _heightCtrl   = TextEditingController(text: profile?.heightCm?.toStringAsFixed(0) ?? '');
    _weightCtrl   = TextEditingController(text: profile?.weightKg?.toStringAsFixed(0) ?? '');

    _dob    = profile?.dateOfBirth;
    _gender = profile?.gender;

    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final rows = await supabase
          .from('addresses')
          .select('label, is_default')
          .eq('user_id', uid)
          .order('is_default', ascending: false)
          .limit(1)
          .maybeSingle();
      if (rows != null && mounted) {
        setState(() => _addressLabel = rows['label'] as String? ?? '');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── DOB picker ────────────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    if (!_editing) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final ctrl    = context.read<ProfileController>();
      final profile = ctrl.profile;
      final uid     = supabase.auth.currentUser!.id;

      // Split Full Name → first + last
      final parts     = _fullNameCtrl.text.trim().split(' ');
      final firstName = parts.first;
      final lastName  = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // 1. Update public.user
      await supabase.from('user').update({
        'first_name': firstName,
        'last_name':  lastName,
        'phone':      _phoneCtrl.text.trim(),
      }).eq('user_id', uid);
      await ctrl.loadUserName(); // refresh cache

      // 2. Recalculate BMI
      final hCm    = double.tryParse(_heightCtrl.text);
      final wKg    = double.tryParse(_weightCtrl.text);
      final newBmi = (hCm != null && wKg != null && hCm > 0)
          ? wKg / ((hCm / 100) * (hCm / 100))
          : profile?.bmi;

      // 3. Update profiles
      await ctrl.updateProfile(ProfileModel(
        id:               profile?.id,
        userId:           uid,
        dateOfBirth:      _dob,
        gender:           _gender ?? profile?.gender,
        heightCm:         hCm ?? profile?.heightCm,
        weightKg:         wKg ?? profile?.weightKg,
        bmi:              newBmi,
        dailyCalorieGoal: profile?.dailyCalorieGoal,
        proteinGoalG:     profile?.proteinGoalG,
        carbsGoalG:       profile?.carbsGoalG,
        fatGoalG:         profile?.fatGoalG,
      ));

      if (mounted) {
        setState(() { _saving = false; _editing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: _editing ? 80 : 56, // give Cancel button enough space
        leading: _editing
            // Edit mode → Cancel text button
            ? TextButton(
                onPressed: () => setState(() => _editing = false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: _orange, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              )
            // View mode → back arrow
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _dark),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'My Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _editing
                ? (_saving ? null : _save)
                : () => setState(() => _editing = true),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _orange))
                : Text(
                    _editing ? 'Save' : 'Edit',
                    style: const TextStyle(
                        color: _green, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: _green,
                child: Icon(Icons.person, size: 42, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Full Name ────────────────────────────────────────────────────
            _field('Full Name', _fullNameCtrl, required: _editing, enabled: _editing),

            // ── Email ────────────────────────────────────────────────────────
            _field('Email', _emailCtrl, enabled: false),

            // ── Phone ────────────────────────────────────────────────────────
            _label('Phone', required: _editing),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: _editing ? Colors.white : const Color(0xFFF8F6F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _editing
                            ? _dark.withValues(alpha: 0.12)
                            : _dark.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    '+ 60',
                    style: TextStyle(
                        fontSize: 14,
                        color: _editing ? _dark : _dark.withValues(alpha: 0.55)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    enabled: _editing,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 14, color: _dark),
                    decoration: _inputDeco(enabled: _editing),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Address (tap to manage) ───────────────────────────────────────
            _label('Address'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _editing ? () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddressesPage()));
                // Clear first so stale label doesn't linger while reloading
                if (mounted) setState(() => _addressLabel = '');
                await _loadDefaultAddress(); // re-fetch from DB on return
              } : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _dark.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _addressLabel.isEmpty ? 'No address set' : _addressLabel,
                      style: TextStyle(
                          fontSize: 14,
                          color: _addressLabel.isEmpty
                              ? _dark.withValues(alpha: 0.4)
                              : _dark),
                    ),
                    if (_editing)
                      Icon(Icons.chevron_right,
                          size: 20, color: _dark.withValues(alpha: 0.35)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── DOB + Gender (side by side) ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date of Birth
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Date of Birth', required: _editing),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDob,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            color: _editing
                                ? Colors.white
                                : const Color(0xFFF8F6F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _editing
                                    ? _dark.withValues(alpha: 0.12)
                                    : _dark.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _dob != null
                                    ? '${_dob!.day.toString().padLeft(2, '0')}-'
                                        '${_dob!.month.toString().padLeft(2, '0')}-'
                                        '${_dob!.year}'
                                    : 'DD-MM-YYYY',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _dob != null
                                        ? _dark
                                        : _dark.withValues(alpha: 0.4)),
                              ),
                              if (_editing)
                                Icon(Icons.calendar_month,
                                    size: 16,
                                    color: _dark.withValues(alpha: 0.4)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Gender
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Gender', required: _editing),
                      const SizedBox(height: 6),
                      if (!_editing)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F6F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _dark.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            _gender ?? '-',
                            style: TextStyle(
                                fontSize: 13,
                                color: _gender != null
                                    ? _dark
                                    : _dark.withValues(alpha: 0.4)),
                          ),
                        )
                      else
                        Row(
                          children: ['Male', 'Female'].map((g) {
                            final sel = _gender == g;
                            return Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: GestureDetector(
                                onTap: () => setState(() => _gender = g),
                                child: Row(
                                  children: [
                                    Icon(
                                      sel
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: sel
                                          ? _green
                                          : _dark.withValues(alpha: 0.4),
                                      size: 17,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(g,
                                        style: const TextStyle(
                                            fontSize: 13, color: _dark)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Height + Weight (side by side) ───────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    'Height (cm)',
                    _heightCtrl,
                    required: _editing,
                    enabled: _editing,
                    type: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'Weight (kg)',
                    _weightCtrl,
                    required: _editing,
                    enabled: _editing,
                    type: TextInputType.numberWithOptions(decimal: true),
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  ),
                ),
              ],
            ),

            // ── BMI (read-only) ───────────────────────────────────────────────
            if (profile?.bmi != null) ...[
              _label('BMI'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _dark.withValues(alpha: 0.08)),
                ),
                child: Text(
                  '${profile!.bmi!.toStringAsFixed(1)} — ${profile.bmiCategory}',
                  style: const TextStyle(fontSize: 14, color: _dark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: 12,
            color: _dark.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500),
        children: required
            ? [
                const TextSpan(
                    text: ' *',
                    style: TextStyle(color: _orange, fontWeight: FontWeight.w700))
              ]
            : [],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    bool enabled = true,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required: required),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: type,
            inputFormatters: formatters,
            style: const TextStyle(fontSize: 14, color: _dark),
            decoration: _inputDeco(enabled: enabled),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({bool enabled = true}) {
    return InputDecoration(
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF8F6F2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _dark.withValues(alpha: 0.12))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _dark.withValues(alpha: 0.12))),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _dark.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange, width: 1.5)),
    );
  }
}
