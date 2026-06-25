import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_error.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_text_field.dart';

// Role labels shown in the segmented button
const _roles = [
  ('student', 'Student'),
  ('company', 'Company'),
  ('teacher', 'Teacher'),
];

const _levels = ['L1', 'L2', 'L3', 'M1', 'M2', 'Doctorate'];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  // Student profile
  final _schoolCtrl = TextEditingController();
  final _programCtrl = TextEditingController();
  String _level = 'L3';
  final _studentPhoneCtrl = TextEditingController();

  // Company profile
  final _companyNameCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _companyPhoneCtrl = TextEditingController();

  // Teacher profile
  final _departmentCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _teacherPhoneCtrl = TextEditingController();

  String _role = 'student';
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _emailCtrl, _passwordCtrl, _firstNameCtrl, _lastNameCtrl,
      _schoolCtrl, _programCtrl, _studentPhoneCtrl,
      _companyNameCtrl, _sectorCtrl, _websiteCtrl, _companyPhoneCtrl,
      _departmentCtrl, _titleCtrl, _teacherPhoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildProfile() {
    return switch (_role) {
      'student' => {
          'school': _schoolCtrl.text.trim(),
          'program': _programCtrl.text.trim(),
          'level': _level,
          if (_studentPhoneCtrl.text.trim().isNotEmpty)
            'phone': _studentPhoneCtrl.text.trim(),
        },
      'company' => {
          'company_name': _companyNameCtrl.text.trim(),
          if (_sectorCtrl.text.trim().isNotEmpty)
            'sector': _sectorCtrl.text.trim(),
          if (_websiteCtrl.text.trim().isNotEmpty)
            'website': _websiteCtrl.text.trim(),
          if (_companyPhoneCtrl.text.trim().isNotEmpty)
            'contact_phone': _companyPhoneCtrl.text.trim(),
        },
      'teacher' => {
          'department': _departmentCtrl.text.trim(),
          if (_titleCtrl.text.trim().isNotEmpty)
            'title': _titleCtrl.text.trim(),
          if (_teacherPhoneCtrl.text.trim().isNotEmpty)
            'phone': _teacherPhoneCtrl.text.trim(),
        },
      _ => {},
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register({
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'role': _role,
        'profile': _buildProfile(),
      });
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    if (e is ApiError) return e.message;
    final msg = e.toString();
    if (msg.contains('ApiError')) {
      final match = RegExp(r'ApiError\(\d+\): (.+)').firstMatch(msg);
      if (match != null) return match.group(1)!;
    }
    if (msg.contains('already exists')) return 'An account with this email already exists.';
    if (msg.contains('connection') || msg.contains('SocketException')) {
      return 'Cannot reach the server. Check your connection.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill in the details below to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Role selector
                    Text('I am a…', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: _roles
                          .map((r) => ButtonSegment(
                                value: r.$1,
                                label: Text(r.$2),
                              ))
                          .toList(),
                      selected: {_role},
                      onSelectionChanged: (s) =>
                          setState(() => _role = s.first),
                    ),
                    const SizedBox(height: 24),

                    // Common fields
                    _SectionLabel('Personal information'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            controller: _firstNameCtrl,
                            label: 'First name',
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AuthTextField(
                            controller: _lastNameCtrl,
                            label: 'Last name',
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newUsername],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'At least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Role-specific profile fields
                    _SectionLabel(_roleLabel()),
                    const SizedBox(height: 12),
                    ..._profileFields(theme),

                    const SizedBox(height: 24),

                    // Error banner
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: theme.textTheme.bodySmall),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign in',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel() => switch (_role) {
        'student' => 'Student details',
        'company' => 'Company details',
        'teacher' => 'Academic details',
        _ => 'Profile details',
      };

  List<Widget> _profileFields(ThemeData theme) {
    return switch (_role) {
      'student' => [
          AuthTextField(
            controller: _schoolCtrl,
            label: 'School / University *',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _programCtrl,
            label: 'Program / Major *',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _level,
            decoration: const InputDecoration(labelText: 'Level *'),
            items: _levels
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => setState(() => _level = v ?? _level),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _studentPhoneCtrl,
            label: 'Phone (optional)',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
        ],
      'company' => [
          AuthTextField(
            controller: _companyNameCtrl,
            label: 'Company name *',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _sectorCtrl,
            label: 'Sector (optional)',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _websiteCtrl,
            label: 'Website (optional)',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _companyPhoneCtrl,
            label: 'Contact phone (optional)',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
        ],
      'teacher' => [
          AuthTextField(
            controller: _departmentCtrl,
            label: 'Department *',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _titleCtrl,
            label: 'Title (optional)',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _teacherPhoneCtrl,
            label: 'Phone (optional)',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
        ],
      _ => [],
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
