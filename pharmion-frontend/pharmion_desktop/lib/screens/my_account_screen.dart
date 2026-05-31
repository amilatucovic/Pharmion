import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../core/errors/app_exception.dart';
import 'login_screen.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});
  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  bool _loading = true;
  String? _error;

  int _userId = 0;
  String _firstName = '';
  String _lastName = '';
  String _username = '';
  String _email = '';
  String _role = '';
  String _licenseNumber = '';
  bool _isAdmin = false;
  bool _isActive = false;
  String _pharmacyName = '';
  String _pharmacyCity = '';
  String? _createdAt;
  String? _lastLoginAt;
  String _gender = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('userId') ?? 0;

      if (_userId == 0) throw Exception('User session not found.');

      final data =
          await ApiService.get('Pharmacist/me') as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _firstName = data['firstName'] as String? ?? '';
          _lastName = data['lastName'] as String? ?? '';
          _username = data['username'] as String? ?? '';
          _email = data['email'] as String? ?? '';
          _role = data['role']?.toString() ?? 'Pharmacist';
          _licenseNumber = data['licenseNumber'] as String? ?? '';
          _isAdmin = data['isAdministrator'] as bool? ?? false;
          _isActive = data['isActive'] as bool? ?? true;
          _pharmacyName = data['pharmacyName'] as String? ?? '';
          _pharmacyCity = data['pharmacyCity'] as String? ?? '';
          _createdAt = data['createdAt'] as String?;
          _lastLoginAt = data['lastLoginAt'] as String?;
          _gender = data['gender']?.toString() ?? '';
          _loading = false;
        });
      }
    } on UnauthorizedException {
      if (mounted) {
        await ApiService.clearToken();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _openChangePassword() => showDialog(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );

  void _openEditProfile() => showDialog(
    context: context,
    builder: (_) => _EditProfileDialog(
      userId: _userId,
      firstName: _firstName,
      lastName: _lastName,
      email: _email,
      licenseNumber: _licenseNumber,
      isAdmin: _isAdmin,
      onSaved: _loadProfile,
    ),
  );

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final normalized = raw.trim().replaceFirst(' ', 'T');
    final withZ = normalized.endsWith('Z') ? normalized : '${normalized}Z';
    final d = DateTime.tryParse(withZ);
    if (d == null) return '—';
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  String _fmtDateTime(String? raw) {
    if (raw == null) return '—';
    final normalized = raw.trim().replaceFirst(' ', 'T');
    final withZ = normalized.endsWith('Z') ? normalized : '${normalized}Z';
    final d = DateTime.tryParse(withZ);
    if (d == null) return '—';
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.kTeal),
      );

    if (_error != null)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: const Color(0xFFDC2626).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.kTextMid, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

    final initials =
        '${_firstName.isNotEmpty ? _firstName[0] : ''}${_lastName.isNotEmpty ? _lastName[0] : ''}'
            .toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.kTeal, Color(0xFF026E73)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_firstName $_lastName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kTextDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$_username',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.kTextMid,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Badge(
                              label: _role,
                              color: AppColors.kTeal,
                              bg: AppColors.kTealLight,
                              icon: Icons.badge_outlined,
                            ),
                            if (_isAdmin) ...[
                              const SizedBox(width: 8),
                              _Badge(
                                label: 'Administrator',
                                color: const Color(0xFF7C3AED),
                                bg: const Color(0xFFEDE9FE),
                                icon: Icons.admin_panel_settings_outlined,
                              ),
                            ],
                            const SizedBox(width: 8),
                            _Badge(
                              label: _isActive ? 'Active' : 'Inactive',
                              color: _isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                              bg: _isActive
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFF1F5F9),
                              icon: _isActive
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openEditProfile,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _openChangePassword,
                        icon: const Icon(Icons.lock_outline, size: 16),
                        label: const Text('Change Password'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.kTeal,
                          side: const BorderSide(color: AppColors.kTeal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _InfoRow(label: 'First Name', value: _firstName),
                      _InfoRow(label: 'Last Name', value: _lastName),
                      _InfoRow(label: 'Username', value: '@$_username'),
                      _InfoRow(label: 'Email', value: _email),
                      _InfoRow(
                        label: 'Gender',
                        value: _gender == '0' || _gender.toLowerCase() == 'male'
                            ? 'Male'
                            : _gender == '1' ||
                                  _gender.toLowerCase() == 'female'
                            ? 'Female'
                            : '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: _InfoCard(
                    title: 'Work Information',
                    icon: Icons.local_pharmacy_outlined,
                    children: [
                      _InfoRow(label: 'Role', value: _role),
                      _InfoRow(
                        label: 'Administrator',
                        value: _isAdmin ? 'Yes' : 'No',
                        valueColor: _isAdmin
                            ? const Color(0xFF059669)
                            : AppColors.kTextMid,
                      ),
                      _InfoRow(
                        label: 'License No.',
                        value: _licenseNumber.isNotEmpty ? _licenseNumber : '—',
                      ),
                      _InfoRow(
                        label: 'Pharmacy',
                        value: _pharmacyName.isNotEmpty ? _pharmacyName : '—',
                      ),
                      _InfoRow(
                        label: 'City',
                        value: _pharmacyCity.isNotEmpty ? _pharmacyCity : '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: _InfoCard(
                    title: 'Account Details',
                    icon: Icons.shield_outlined,
                    children: [
                      _InfoRow(
                        label: 'Status',
                        value: _isActive ? 'Active' : 'Inactive',
                        valueColor: _isActive
                            ? const Color(0xFF059669)
                            : const Color(0xFF64748B),
                      ),
                      _InfoRow(
                        label: 'Member Since',
                        value: _fmtDate(_createdAt),
                      ),
                      _InfoRow(
                        label: 'Last Login',
                        value: _fmtDateTime(_lastLoginAt),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openChangePassword,
                          icon: const Icon(Icons.lock_reset_outlined, size: 15),
                          label: const Text(
                            'Change Password',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.kTeal,
                            side: const BorderSide(color: AppColors.kTeal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final int userId;
  final String firstName, lastName, email, licenseNumber;
  final bool isAdmin;
  final VoidCallback onSaved;

  const _EditProfileDialog({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.licenseNumber,
    required this.isAdmin,
    required this.onSaved,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _licenseCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.firstName);
    _lastNameCtrl = TextEditingController(text: widget.lastName);
    _emailCtrl = TextEditingController(text: widget.email);
    _licenseCtrl = TextEditingController(text: widget.licenseNumber);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'First and last name are required.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Email is required.');
      return;
    }
    if (_licenseCtrl.text.trim().isEmpty) {
      setState(() => _error = 'License number is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final current =
          await ApiService.get('Pharmacist/${widget.userId}')
              as Map<String, dynamic>;

      await ApiService.put('Pharmacist/${widget.userId}', {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'licenseNumber': _licenseCtrl.text.trim(),
        'pharmacyId': current['pharmacyId'],
        'isAdministrator': current['isAdministrator'],
        'isActive': current['isActive'],
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firstName', _firstNameCtrl.text.trim());
      await prefs.setString('lastName', _lastNameCtrl.text.trim());

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Profile updated successfully.'),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _deco(String label, {String? hint}) => InputDecoration(
    hintText: hint ?? label,
    labelStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.kTeal, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.kTealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.kTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kTextDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.kTextMid,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 14,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: _FieldCol(
                      label: 'First Name *',
                      child: TextField(
                        controller: _firstNameCtrl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.kTextDark,
                        ),
                        decoration: _deco('First Name'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldCol(
                      label: 'Last Name *',
                      child: TextField(
                        controller: _lastNameCtrl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.kTextDark,
                        ),
                        decoration: _deco('Last Name'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _FieldCol(
                label: 'Email *',
                child: TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextDark,
                  ),
                  decoration: _deco('Email'),
                ),
              ),
              const SizedBox(height: 12),

              _FieldCol(
                label: 'License Number *',
                child: TextField(
                  controller: _licenseCtrl,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextDark,
                  ),
                  decoration: _deco(
                    'License Number',
                    hint: 'e.g. MAG-2022-0001',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (!widget.isAdmin) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pharmacy and role can only be changed by an administrator.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextMid,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 15),
                    label: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldCol extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldCol({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.kTextMid,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color, bg;
  final IconData icon;
  const _Badge({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.kTeal),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.kTextMid,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? AppColors.kTextDark,
              fontWeight: valueColor != null
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showOld = false, _showNew = false, _showConfirm = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final oldPass = _oldCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (oldPass.isEmpty) {
      setState(() => _error = 'Current password is required.');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (oldPass == newPass) {
      setState(
        () => _error = 'New password must be different from the current one.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.post('Auth/change-password', {
        'oldPassword': oldPass,
        'newPassword': newPass,
        'confirmNewPassword': newPass,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Password changed successfully.'),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _deco(String label, bool show, VoidCallback toggle) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: AppColors.kTextMid,
          ),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kTeal, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.kTealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.kTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kTextDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.kTextMid,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 14,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: _oldCtrl,
                obscureText: !_showOld,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _deco(
                  'Current Password',
                  _showOld,
                  () => setState(() => _showOld = !_showOld),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newCtrl,
                obscureText: !_showNew,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _deco(
                  'New Password',
                  _showNew,
                  () => setState(() => _showNew = !_showNew),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: !_showConfirm,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextDark,
                ),
                decoration: _deco(
                  'Confirm New Password',
                  _showConfirm,
                  () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Minimum 8 characters.',
                style: TextStyle(fontSize: 11, color: AppColors.kTextMid),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextMid,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 15),
                    label: const Text(
                      'Update Password',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
