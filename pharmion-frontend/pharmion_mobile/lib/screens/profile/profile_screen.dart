import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _patient;
  List<dynamic> _myDiseases = [];
  List<dynamic> _allDiseases = [];
  bool _loading = true;
  bool _diseasesLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final patient =
          await ApiService.get('Patient/me') as Map<String, dynamic>;
      final diseases =
          await ApiService.get('PatientChronicDisease') as List<dynamic>;
      if (mounted)
        setState(() {
          _patient = patient;
          _myDiseases = diseases;
        });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAllDiseases() async {
    setState(() => _diseasesLoading = true);
    try {
      final data =
          await ApiService.get('ChronicDisease?pageSize=100&isActive=true')
              as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? [];
      if (mounted) setState(() => _allDiseases = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _diseasesLoading = false);
    }
  }

  Future<void> _addDisease(int id) async {
    try {
      await ApiService.post('PatientChronicDisease/$id', {});
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Disease added successfully'),
          backgroundColor: AppColors.kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  Future<void> _removeDisease(int chronicDiseaseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Disease',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to remove this disease from your profile?',
            style: TextStyle(fontSize: 13, color: AppColors.kTextMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.kTextMid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kError,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.delete('PatientChronicDisease/$chronicDiseaseId');
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  void _showAddDiseaseSheet() async {
    await _loadAllDiseases();
    if (!mounted) return;

    final myIds = _myDiseases.map((d) => d['chronicDiseaseId'] as int).toSet();
    final available =
        _allDiseases.where((d) => !myIds.contains(d['id'])).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          size: 20, color: AppColors.kTextMid),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Add Chronic Disease',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark)),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.kBorder),
              Expanded(
                child: _diseasesLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.kTeal))
                    : available.isEmpty
                        ? const Center(
                            child: Text('No more diseases to add',
                                style: TextStyle(color: AppColors.kTextMid)))
                        : ListView.separated(
                            controller: ctrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: available.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: AppColors.kBorder),
                            itemBuilder: (context, index) {
                              final disease = available[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.kTealLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.medical_information_outlined,
                                      color: AppColors.kTeal,
                                      size: 20),
                                ),
                                title: Text(
                                  disease['name'] as String? ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.kTextDark),
                                ),
                                subtitle: Text(
                                  disease['code'] as String? ?? '',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.kTextMid),
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _addDisease(disease['id'] as int);
                                  },
                                  icon: const Icon(Icons.add_circle,
                                      color: AppColors.kTeal, size: 28),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.kErrorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(error!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kError)),
                ),
                const SizedBox(height: 12),
              ],
              _PasswordField(controller: oldCtrl, label: 'Current Password'),
              const SizedBox(height: 12),
              _PasswordField(controller: newCtrl, label: 'New Password'),
              const SizedBox(height: 4),
              const Text(
                'Minimum 8 characters',
                style: TextStyle(fontSize: 11, color: AppColors.kTextMid),
              ),
              const SizedBox(height: 8),
              _PasswordField(
                  controller: confirmCtrl, label: 'Confirm New Password'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.kTextMid)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        setDialogState(() => error = 'Passwords do not match');
                        return;
                      }
                      setDialogState(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        await ApiService.post('Auth/change-password', {
                          'oldPassword': oldCtrl.text,
                          'newPassword': newCtrl.text,
                          'confirmNewPassword': confirmCtrl.text,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted)
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Password changed successfully'),
                            backgroundColor: AppColors.kSuccess,
                            behavior: SnackBarBehavior.floating,
                          ));
                      } catch (e) {
                        setDialogState(() {
                          error = e.toString().replaceAll('Exception: ', '');
                          loading = false;
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(fontSize: 13, color: AppColors.kTextMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.kTextMid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kError,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: AppColors.kError, size: 22),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kTeal))
          : RefreshIndicator(
              color: AppColors.kTeal,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + name ──────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.kTeal,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_patient?['firstName'] ?? ''} ${_patient?['lastName'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _patient?['email'] ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.kTextMid),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: (_patient?['isInsured'] == true)
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (_patient?['isInsured'] == true)
                                  ? 'Insured'
                                  : 'Not insured',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: (_patient?['isInsured'] == true)
                                      ? AppColors.kSuccess
                                      : AppColors.kTextMid),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Personal info ──────────────────────────────
                    _SectionTitle(title: 'Personal Information'),
                    const SizedBox(height: 10),
                    _InfoCard(children: [
                      _InfoRow(
                          icon: Icons.person_outlined,
                          label: 'Username',
                          value: _patient?['username'] ?? '—'),
                      _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _patient?['phoneNumber'] ?? '—'),
                      _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: _patient?['address'] ?? '—'),
                      _InfoRow(
                          icon: Icons.location_city_outlined,
                          label: 'City',
                          value: _patient?['cityName'] ?? '—'),
                      _InfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Date of Birth',
                          value: _patient?['dateOfBirth'] != null
                              ? AppDateUtils.formatDate(
                                  DateTime.parse(_patient!['dateOfBirth']))
                              : '—'),
                      _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Gender',
                          value: _patient?['genderDisplay'] ?? '—'),
                    ]),
                    const SizedBox(height: 20),

                    // ── Chronic diseases ───────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(title: 'Chronic Diseases'),
                        TextButton.icon(
                          onPressed: _showAddDiseaseSheet,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.kTeal,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _myDiseases.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.kBorder),
                            ),
                            child: const Row(children: [
                              Icon(Icons.info_outline,
                                  size: 18, color: AppColors.kTextLight),
                              SizedBox(width: 10),
                              Text('No chronic diseases recorded',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.kTextMid)),
                            ]),
                          )
                        : Column(
                            children: _myDiseases
                                .map((d) => _DiseaseCard(
                                      name: d['name'] as String? ?? '',
                                      code: d['code'] as String? ?? '',
                                      onRemove: () => _removeDisease(
                                          d['chronicDiseaseId'] as int),
                                    ))
                                .toList(),
                          ),
                    const SizedBox(height: 20),

                    // ── Security ───────────────────────────────────
                    _SectionTitle(title: 'Security'),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: _showChangePasswordDialog,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  String _getInitials() {
    final first = (_patient?['firstName'] as String? ?? '');
    final last = (_patient?['lastName'] as String? ?? '');
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }
}

// ─── Password Field ───────────────────────────────────────────────────────────
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PasswordField({required this.controller, required this.label});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        obscureText: _obscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.kTextMid),
          suffixIcon: IconButton(
            icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.kTextMid),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.kTeal, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

// ─── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.kTextDark),
      );
}

// ─── Info Card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.kTealLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.kTeal),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.kTextMid)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kTextDark)),
          ),
        ]),
      );
}

// ─── Disease Card ─────────────────────────────────────────────────────────────
class _DiseaseCard extends StatelessWidget {
  final String name;
  final String code;
  final VoidCallback onRemove;
  const _DiseaseCard(
      {required this.name, required this.code, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medical_information_outlined,
                color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextDark)),
                Text(code,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.kTextMid)),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.kError),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      );
}

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.kTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextDark)),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.kTextLight, size: 20),
          ]),
        ),
      );
}
