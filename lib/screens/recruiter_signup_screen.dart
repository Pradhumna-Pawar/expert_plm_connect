import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'recruiter_login_screen.dart';
import 'home_screen.dart';

class RecruiterSignupScreen extends StatefulWidget {
  const RecruiterSignupScreen({super.key});

  @override
  State<RecruiterSignupScreen> createState() => _RecruiterSignupScreenState();
}

class _RecruiterSignupScreenState extends State<RecruiterSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  final _chatService = ChatService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnackBar('Please agree to Terms & Conditions to continue.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signUpWithEmail(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted && cred.user != null) {
        await _chatService.saveUserProfile(
          uid: cred.user!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: 'recruiter',
          company: _companyController.text.trim(),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => RecruiterHomeScreen(
                userName: _nameController.text.trim()),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null && mounted) {
        final user = result.user!;
        await _chatService.saveUserProfile(
          uid: user.uid,
          name: user.displayName ?? 'Recruiter',
          email: user.email ?? '',
          role: 'recruiter',
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => RecruiterHomeScreen(
                userName: user.displayName ?? 'Recruiter'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? RecruiterColors.accent : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Back ──
                _BackButton(),
                const SizedBox(height: 24),

                // ── Logo ──
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [RecruiterColors.accent, RecruiterColors.accentDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Heading ──
                const Center(
                  child: Text(
                    'Create Recruiter Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Find top talent and grow your team',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Google ──
                _RecruiterGoogleButton(
                    onTap: _isLoading ? null : _signInWithGoogle),
                const SizedBox(height: 20),

                _OrDivider(),
                const SizedBox(height: 20),

                // ── Full Name ──
                _FieldLabel('Full Name'),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _nameController,
                  hintText: 'Jane Smith',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your full name'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Company Name ──
                _FieldLabel('Company Name'),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _companyController,
                  hintText: 'Acme Corp',
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: Icons.business_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your company name'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Email ──
                _FieldLabel('Work Email'),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _emailController,
                  hintText: 'jane@company.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ──
                _FieldLabel('Password'),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _passwordController,
                  hintText: '••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: _ToggleVisibilityButton(
                    isObscure: _obscurePassword,
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm Password ──
                _FieldLabel('Confirm Password'),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _confirmPasswordController,
                  hintText: '••••••••',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: _ToggleVisibilityButton(
                    isObscure: _obscureConfirmPassword,
                    onTap: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Terms ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        activeColor: RecruiterColors.accent,
                        checkColor: Colors.white,
                        side: const BorderSide(color: AppColors.textHint, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                  color: RecruiterColors.accent,
                                  fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                  color: RecruiterColors.accent,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Create Account Button ──
                _PrimaryButton(
                  label: 'Create Recruiter Account',
                  isLoading: _isLoading,
                  onTap: _isLoading ? null : _signUpWithEmail,
                ),
                const SizedBox(height: 20),

                // ── Already have account ──
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Already have an account?  ',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecruiterLoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: RecruiterColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Recruiter Color Palette
// ─────────────────────────────────────────────

class RecruiterColors {
  static const Color accent = Color(0xFF5B9BD5);
  static const Color accentDark = Color(0xFF3A7BBF);
}

// ─────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 16,
        ),
      ),
    );
  }
}

class _RecruiterGoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _RecruiterGoogleButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH EMAIL',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textHint, size: 20)
            : null,
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RecruiterColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
        ),
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(color: Color(0xFFE74C3C), fontSize: 12),
      ),
    );
  }
}

class _ToggleVisibilityButton extends StatelessWidget {
  final bool isObscure;
  final VoidCallback onTap;
  const _ToggleVisibilityButton({required this.isObscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textHint,
        size: 20,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [RecruiterColors.accent, RecruiterColors.accentDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: RecruiterColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
