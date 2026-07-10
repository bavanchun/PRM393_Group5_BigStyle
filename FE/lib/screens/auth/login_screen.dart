import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../utils/validators.dart';
import 'otp_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _testManagerEmail = String.fromEnvironment(
    'BIGSTYLE_TEST_MANAGER_EMAIL',
  );
  static const _testManagerPassword = String.fromEnvironment(
    'BIGSTYLE_TEST_MANAGER_PASSWORD',
  );
  static const _testCustomerEmail = String.fromEnvironment(
    'BIGSTYLE_TEST_CUSTOMER_EMAIL',
  );
  static const _testCustomerPassword = String.fromEnvironment(
    'BIGSTYLE_TEST_CUSTOMER_PASSWORD',
  );

  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<OtpInputState>();
  bool _showOtp = false;
  // True between dispatching a VerifyOTPEvent and the next terminal auth state.
  // Gates the OTP boxes / resend / Google / debug triggers and scopes the
  // clear-on-error so a concurrent send or Google failure can't wipe the code.
  bool _verifyInFlight = false;

  // Client-side resend courtesy countdown (per email). Not abuse protection —
  // the server rate limits are the real guard; this only avoids obvious spam.
  Timer? _resendTimer;
  int _cooldown = 0;
  String? _cooldownEmail;
  // The email that actually received the current code, so verify targets it
  // rather than whatever is in the field after an edit.
  String? _otpEmail;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown(String email) {
    _resendTimer?.cancel();
    setState(() {
      _cooldown = 60;
      _cooldownEmail = email;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) {
          _cooldown = 0;
          t.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthOTPSent) {
                _otpEmail = state.email;
                setState(() => _showOtp = true);
              }
              if (state is AuthSuccess) {
                _verifyInFlight = false;
                final user = state.user;
                if (user == null) return;
                String route;
                switch (user.role.name) {
                  case 'admin':
                    route = '/admin';
                    break;
                  case 'manager':
                    route = '/manager';
                    break;
                  default:
                    route = '/home';
                }
                Navigator.pushReplacementNamed(context, route);
              }
              if (state is AuthError) {
                // Only a verify-originated error clears the boxes; resend and
                // Google errors leave the entered code intact.
                if (_verifyInFlight) {
                  _otpKey.currentState?.clear();
                  setState(() => _verifyInFlight = false);
                }
                final raw = state.message;
                final isRateLimit =
                    raw.toLowerCase().contains('rate limit') ||
                    raw.contains('over_email_send_rate_limit');
                final message = isRateLimit
                    ? 'Bạn gửi mã quá nhanh. Vui lòng thử lại sau ít phút.'
                    : raw;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildHeroImage(),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            if (!_showOtp) ...[
                              _buildSendOtpButton(state),
                            ] else ...[
                              _buildOtpSection(state),
                            ],
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            _buildGoogleButton(state),
                            if (_hasDebugTestLogin) ...[
                              const SizedBox(height: 16),
                              _buildDebugTestLoginButtons(state),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'BigStyle',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mặc đẹp không giới hạn',
          style: AppTypography.bodyMedium.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.secondary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.checkroom,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TỰ TIN VỚI',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PHONG CÁCH\nRIÊNG CỦA BẠN',
                  style: AppTypography.displaySmall.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Email của bạn',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: validateEmail,
    );
  }

  Widget _buildSendOtpButton(AuthState state) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state is AuthLoading ? null : _sendOtp,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: state is AuthLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text(
                    'Gửi mã OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpSection(AuthState state) {
    return Column(
      children: [
        Text(
          'Nhập mã xác thực',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        OtpInput(
          key: _otpKey,
          enabled: !_verifyInFlight,
          resendEnabled: _cooldown == 0,
          resendLabel: _cooldown > 0 ? 'Gửi lại sau ${_cooldown}s' : null,
          onCompleted: (code) {
            final email = _otpEmail ?? _emailController.text.trim();
            setState(() => _verifyInFlight = true);
            context.read<AuthBloc>().add(VerifyOTPEvent(email, code));
          },
          onResend: _sendOtp,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: AppTypography.caption.copyWith(color: AppColors.textHint),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildGoogleButton(AuthState state) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: (state is AuthLoading || _verifyInFlight)
            ? null
            : () => context.read<AuthBloc>().add(const GoogleSignInEvent()),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.g_mobiledata, size: 28, color: AppColors.accent),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Đăng nhập với Google',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasDebugTestLogin {
    return kDebugMode &&
        ((_testManagerEmail.isNotEmpty && _testManagerPassword.isNotEmpty) ||
            (_testCustomerEmail.isNotEmpty &&
                _testCustomerPassword.isNotEmpty));
  }

  Widget _buildDebugTestLoginButtons(AuthState state) {
    final isLoading = state is AuthLoading || _verifyInFlight;
    return Row(
      children: [
        if (_testManagerEmail.isNotEmpty && _testManagerPassword.isNotEmpty)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _signInTestUser(
                      _testManagerEmail,
                      _testManagerPassword,
                    ),
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: const Text('Manager test'),
            ),
          ),
        if (_testManagerEmail.isNotEmpty &&
            _testManagerPassword.isNotEmpty &&
            _testCustomerEmail.isNotEmpty &&
            _testCustomerPassword.isNotEmpty)
          const SizedBox(width: 12),
        if (_testCustomerEmail.isNotEmpty && _testCustomerPassword.isNotEmpty)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _signInTestUser(
                      _testCustomerEmail,
                      _testCustomerPassword,
                    ),
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Customer test'),
            ),
          ),
      ],
    );
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    if (_cooldown > 0 && email == _cooldownEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng đợi ${_cooldown}s trước khi gửi lại'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(SendOTPEvent(email));
    _startCooldown(email);
  }

  void _signInTestUser(String email, String password) {
    context.read<AuthBloc>().add(
      PasswordSignInEvent(email: email, password: password),
    );
  }
}
