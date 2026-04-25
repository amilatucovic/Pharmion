import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/forms/app_text_field.dart';
import '../../widgets/forms/form_card.dart';
import '../../widgets/forms/form_field_wrapper.dart';
import '../../widgets/forms/gender_chip.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _firstNameCtrl   = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _jmbgCtrl        = TextEditingController();
  final _insuranceCtrl   = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _emergencyCtrl   = TextEditingController();

  bool _showPassword        = false;
  bool _showConfirmPassword = false;
  int? _selectedGender;
  DateTime? _dateOfBirth;
  int? _selectedCityId;
  bool _isInsured = false;

  List<Map<String, dynamic>> _cities = [];
  bool _loadingCities = false;

  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _usernameCtrl, _emailCtrl,
      _passwordCtrl, _confirmPassCtrl, _jmbgCtrl, _insuranceCtrl,
      _addressCtrl, _phoneCtrl, _emergencyCtrl,
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() => _loadingCities = true);
    try {
      final data = await ApiService.get('City?pageSize=100&retrieveAll=true', auth: false)
          as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _cities = ((data['items'] as List?) ?? [])
              .map((c) => {'id': c['id'], 'name': c['name']})
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  // ── Validations ────────────────────────────────────────────────────────────

  bool _validatePage1() {
    final errors = <String, String?>{};

    if (_firstNameCtrl.text.trim().isEmpty)
      errors['firstName'] = 'First name is required.';
    else if (_firstNameCtrl.text.trim().length < 2)
      errors['firstName'] = 'First name must be at least 2 characters.';

    if (_lastNameCtrl.text.trim().isEmpty)
      errors['lastName'] = 'Last name is required.';
    else if (_lastNameCtrl.text.trim().length < 2)
      errors['lastName'] = 'Last name must be at least 2 characters.';

    if (_usernameCtrl.text.trim().isEmpty)
      errors['username'] = 'Username is required.';
    else if (_usernameCtrl.text.trim().length < 3)
      errors['username'] = 'Username must be at least 3 characters.';
    else if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(_usernameCtrl.text.trim()))
      errors['username'] =
          'Username can only contain letters, numbers, dots and underscores.';

    if (_emailCtrl.text.trim().isEmpty)
      errors['email'] = 'Email is required.';
    else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
        .hasMatch(_emailCtrl.text.trim()))
      errors['email'] = 'Please enter a valid email address.';

    if (_passwordCtrl.text.isEmpty)
      errors['password'] = 'Password is required.';
    else if (_passwordCtrl.text.length < 8)
      errors['password'] = 'Password must be at least 8 characters.';
    else if (!RegExp(r'(?=.*[A-Z])').hasMatch(_passwordCtrl.text))
      errors['password'] =
          'Password must contain at least one uppercase letter.';
    else if (!RegExp(r'(?=.*[0-9])').hasMatch(_passwordCtrl.text))
      errors['password'] = 'Password must contain at least one number.';

    if (_confirmPassCtrl.text.isEmpty)
      errors['confirmPassword'] = 'Please confirm your password.';
    else if (_confirmPassCtrl.text != _passwordCtrl.text)
      errors['confirmPassword'] = 'Passwords do not match.';

    setState(() => _errors.addAll(errors));
    return errors.isEmpty;
  }

  bool _validatePage2() {
    final errors = <String, String?>{};

    if (_selectedGender == null)
      errors['gender'] = 'Please select your gender.';

    if (_dateOfBirth == null) {
      errors['dateOfBirth'] = 'Date of birth is required.';
    } else {
      final age = DateTime.now().difference(_dateOfBirth!).inDays ~/ 365;
      if (age < 18)
        errors['dateOfBirth'] = 'You must be at least 18 years old.';
    }

    if (_jmbgCtrl.text.trim().isEmpty)
      errors['jmbg'] = 'JMBG is required.';
    else if (_jmbgCtrl.text.trim().length != 13)
      errors['jmbg'] = 'JMBG must be exactly 13 digits.';
    else if (!RegExp(r'^\d{13}$').hasMatch(_jmbgCtrl.text.trim()))
      errors['jmbg'] = 'JMBG must contain only digits.';

    if (_phoneCtrl.text.trim().isEmpty)
      errors['phone'] = 'Phone number is required.';
    else if (!RegExp(r'^\+?[\d\s\-]{9,15}$')
        .hasMatch(_phoneCtrl.text.trim()))
      errors['phone'] = 'Please enter a valid phone number.';

    if (_addressCtrl.text.trim().isEmpty)
      errors['address'] = 'Address is required.';
    else if (_addressCtrl.text.trim().length < 5)
      errors['address'] = 'Please enter a valid address.';

    if (_selectedCityId == null)
      errors['city'] = 'Please select your city.';

    setState(() => _errors.addAll(errors));
    return errors.isEmpty;
  }

  void _clearError(String field) {
    if (_errors[field] != null) setState(() => _errors[field] = null);
  }

  void _nextPage() {
    setState(() => _errors.clear());
    if (_currentPage == 0 && !_validatePage1()) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() => _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.kTeal),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _errors['dateOfBirth'] = null;
      });
    }
  }

  Future<void> _register() async {
    if (!_validatePage2()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final success = await auth.register({
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'confirmPassword': _confirmPassCtrl.text,
      'gender': _selectedGender,
      'dateOfBirth': _dateOfBirth!.toIso8601String(),
      'jmbg': _jmbgCtrl.text.trim(),
      if (_insuranceCtrl.text.trim().isNotEmpty)
        'insuranceNumber': _insuranceCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'cityId': _selectedCityId,
      'phoneNumber': _phoneCtrl.text.trim(),
      if (_emergencyCtrl.text.trim().isNotEmpty)
        'emergencyContact': _emergencyCtrl.text.trim(),
      'isInsured': _isInsured,
    });
    if (success && mounted) context.go('/');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.kTextMid),
          onPressed: _currentPage > 0
              ? _prevPage
              : () => context.go('/auth/login'),
        ),
        title: Text(
          _currentPage == 0 ? 'Create Account' : 'Personal Details',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextDark),
        ),
      ),
      body: Column(children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(2, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                    right: i == 0 ? 4 : 0, left: i == 1 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _currentPage
                      ? AppColors.kTeal
                      : AppColors.kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Step ${_currentPage + 1} of 2',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.kTextMid)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [_buildPage1(), _buildPage2()],
          ),
        ),
      ]),
    );
  }

  // ── Page 1 ─────────────────────────────────────────────────────────────────
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FormCard(children: [
          Row(children: [
            Expanded(child: FormFieldWrapper(
              label: 'First Name *',
              error: _errors['firstName'],
              child: AppTextField(
                controller: _firstNameCtrl,
                hint: 'e.g. Amina',
                error: _errors['firstName'],
                onChanged: (_) => _clearError('firstName'),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: FormFieldWrapper(
              label: 'Last Name *',
              error: _errors['lastName'],
              child: AppTextField(
                controller: _lastNameCtrl,
                hint: 'e.g. Hodžić',
                error: _errors['lastName'],
                onChanged: (_) => _clearError('lastName'),
              ),
            )),
          ]),
          const SizedBox(height: 16),
          FormFieldWrapper(
            label: 'Username *',
            hint: 'Letters, numbers, dots and underscores only',
            error: _errors['username'],
            child: AppTextField(
              controller: _usernameCtrl,
              hint: 'e.g. amina.hodzic',
              error: _errors['username'],
              onChanged: (_) => _clearError('username'),
              prefixIcon: Icons.alternate_email,
            ),
          ),
          const SizedBox(height: 16),
          FormFieldWrapper(
            label: 'Email *',
            error: _errors['email'],
            child: AppTextField(
              controller: _emailCtrl,
              hint: 'e.g. amina@email.com',
              error: _errors['email'],
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _clearError('email'),
              prefixIcon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 16),
          FormFieldWrapper(
            label: 'Password *',
            hint: 'Min 8 characters, 1 uppercase, 1 number',
            error: _errors['password'],
            child: AppTextField(
              controller: _passwordCtrl,
              hint: '••••••••',
              error: _errors['password'],
              obscureText: !_showPassword,
              onChanged: (_) => _clearError('password'),
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.kTextMid, size: 20),
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FormFieldWrapper(
            label: 'Confirm Password *',
            error: _errors['confirmPassword'],
            child: AppTextField(
              controller: _confirmPassCtrl,
              hint: '••••••••',
              error: _errors['confirmPassword'],
              obscureText: !_showConfirmPassword,
              onChanged: (_) => _clearError('confirmPassword'),
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.kTextMid, size: 20),
                onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _nextPage,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continue'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Already have an account? ',
              style: TextStyle(fontSize: 14, color: AppColors.kTextMid)),
          GestureDetector(
            onTap: () => context.go('/auth/login'),
            child: const Text('Sign In',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.kTeal,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  // ── Page 2 ─────────────────────────────────────────────────────────────────
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Backend error
        Consumer<AuthProvider>(builder: (_, auth, __) {
          if (auth.error == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.kErrorLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.kError.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline,
                  size: 16, color: AppColors.kError),
              const SizedBox(width: 8),
              Expanded(child: Text(auth.error!,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.kError))),
            ]),
          );
        }),

        FormCard(children: [
          // Gender
          FormFieldWrapper(
            label: 'Gender *',
            error: _errors['gender'],
            child: Row(children: [
              Expanded(child: GenderChip(
                label: 'Male',
                icon: Icons.male,
                selected: _selectedGender == 1,
                onTap: () => setState(() {
                  _selectedGender = 1;
                  _errors['gender'] = null;
                }),
              )),
              const SizedBox(width: 12),
              Expanded(child: GenderChip(
                label: 'Female',
                icon: Icons.female,
                selected: _selectedGender == 2,
                onTap: () => setState(() {
                  _selectedGender = 2;
                  _errors['gender'] = null;
                }),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // Date of Birth
          FormFieldWrapper(
            label: 'Date of Birth *',
            hint: 'Must be at least 18 years old',
            error: _errors['dateOfBirth'],
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _errors['dateOfBirth'] != null
                        ? AppColors.kError
                        : AppColors.kBorder,
                  ),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.kTextMid),
                  const SizedBox(width: 10),
                  Text(
                    _dateOfBirth == null
                        ? 'Select date of birth'
                        : '${_dateOfBirth!.day.toString().padLeft(2, '0')}.${_dateOfBirth!.month.toString().padLeft(2, '0')}.${_dateOfBirth!.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _dateOfBirth == null
                          ? AppColors.kTextLight
                          : AppColors.kTextDark,
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // JMBG
          FormFieldWrapper(
            label: 'JMBG *',
            hint: '13 digits',
            error: _errors['jmbg'],
            child: AppTextField(
              controller: _jmbgCtrl,
              hint: '1234567890123',
              error: _errors['jmbg'],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              onChanged: (_) => _clearError('jmbg'),
              prefixIcon: Icons.badge_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Phone
          FormFieldWrapper(
            label: 'Phone Number *',
            error: _errors['phone'],
            child: AppTextField(
              controller: _phoneCtrl,
              hint: 'e.g. 061 123 456',
              error: _errors['phone'],
              keyboardType: TextInputType.phone,
              onChanged: (_) => _clearError('phone'),
              prefixIcon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Address
          FormFieldWrapper(
            label: 'Address *',
            error: _errors['address'],
            child: AppTextField(
              controller: _addressCtrl,
              hint: 'e.g. Ulica bb, Mostar',
              error: _errors['address'],
              onChanged: (_) => _clearError('address'),
              prefixIcon: Icons.home_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // City
          FormFieldWrapper(
            label: 'City *',
            error: _errors['city'],
            child: _loadingCities
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.kTeal, strokeWidth: 2))
                : DropdownButtonFormField<int>(
                    value: _selectedCityId,
                    hint: const Text('Select city',
                        style: TextStyle(
                            color: AppColors.kTextLight,
                            fontSize: 14)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errors['city'] != null
                              ? AppColors.kError
                              : AppColors.kBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errors['city'] != null
                              ? AppColors.kError
                              : AppColors.kBorder,
                        ),
                      ),
                    ),
                    items: _cities
                        .map((c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['name'] as String,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedCityId = v;
                      _errors['city'] = null;
                    }),
                  ),
          ),
          const SizedBox(height: 16),

          // Insurance (optional)
          FormFieldWrapper(
            label: 'Insurance Number',
            hint: 'Optional',
            child: AppTextField(
              controller: _insuranceCtrl,
              hint: 'e.g. 123456789',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.health_and_safety_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Emergency (optional)
          FormFieldWrapper(
            label: 'Emergency Contact',
            hint: 'Optional',
            child: AppTextField(
              controller: _emergencyCtrl,
              hint: 'e.g. 061 987 654',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.emergency_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Is insured toggle
          GestureDetector(
            onTap: () => setState(() => _isInsured = !_isInsured),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isInsured
                    ? AppColors.kTealLight
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isInsured
                      ? AppColors.kTeal
                      : AppColors.kBorder,
                ),
              ),
              child: Row(children: [
                Icon(
                  _isInsured
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _isInsured
                      ? AppColors.kTeal
                      : AppColors.kTextLight,
                  size: 22,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('I have health insurance',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.kTextDark)),
                      SizedBox(height: 2),
                      Text(
                          'Check if you are covered by health insurance',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.kTextMid)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        Consumer<AuthProvider>(
          builder: (_, auth, __) => ElevatedButton(
            onPressed: auth.loading ? null : _register,
            child: auth.loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create Account'),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}