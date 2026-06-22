import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_strings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: "");
  final _otpController = TextEditingController();

  bool _isOtpState = false;
  Timer? _timer;
  int _timeRemaining = 600; // 10 minutes

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeRemaining = 600;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).sendOtp(
            _emailController.text.trim(),
          );
      if (success && mounted) {
        _startTimer();
        setState(() {
          _isOtpState = true;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length >= 4) {
      try {
        final success = await ref.read(authProvider.notifier).verifyOtp(
              _emailController.text.trim(),
              _otpController.text.trim(),
            );
        if (!success && mounted) {
           // We might just be waiting for the error state to render. Or if error state failed:
           final error = ref.read(authProvider).error;
           if (error == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error: OTP request failed silently.")),
              );
           }
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Critical Error: $e"), backgroundColor: Colors.red),
           );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete OTP")),
      );
    }
  }

  Future<void> _resendOtp() async {
    final success = await ref.read(authProvider.notifier).sendOtp(
          _emailController.text.trim(),
        );
    if (success && mounted) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("OTP has been resent to your email"),
          backgroundColor: AppColors.primaryButtonColor,
        ),
      );
    }
  }

  void _changeEmail() {
    _timer?.cancel();
    setState(() {
      _isOtpState = false;
      _otpController.clear();
      _timeRemaining = 600;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Header
                  Text(
                    _isOtpState ? "Verify OTP" : AppStrings.welcomeBack,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOtpState 
                        ? "Enter the OTP sent to your email" 
                        : AppStrings.accessProgram,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  if (!_isOtpState) ...[
                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: AppStrings.emailAddress, 
                        prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      enabled: !authState.isLoading,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Continue Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButtonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    "Continue",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ],

                  if (_isOtpState) ...[
                    // Professional Custom OTP Input
                    Stack(
                      children: [
                        // The visual OTP boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            // Determine if this box is currently focused or filled
                            final isFilled = _otpController.text.length > index;
                            final isCurrent = _otpController.text.length == index && !authState.isLoading;
                            
                            return Container(
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isFilled ? Colors.white : const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent 
                                      ? AppColors.primaryColor 
                                      : (isFilled ? AppColors.primaryColor.withOpacity(0.5) : const Color(0xFFEEEEEE)),
                                  width: isCurrent ? 2 : 1,
                                ),
                                boxShadow: isCurrent ? [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isFilled ? _otpController.text[index] : "",
                                style: AppTextStyles.h2.copyWith(
                                  fontSize: 24,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }),
                        ),
                        // The invisible text field that captures input
                        Positioned.fill(
                          child: TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            onChanged: (val) {
                              setState(() {}); // Refresh visual boxes
                              if (val.length == 6) {
                                // Provide a tiny delay for UX so they see the final digit appear before the API fires
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) _verifyOtp();
                                });
                              }
                            },
                            showCursor: false,
                            autofocus: true,
                            enableInteractiveSelection: false,
                            style: const TextStyle(color: Colors.transparent, fontSize: 1),
                            decoration: const InputDecoration(
                              counterText: "",
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: true,
                            ),
                            enabled: !authState.isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Options Row: Change Email and Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: authState.isLoading ? null : _changeEmail,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Change Email", style: TextStyle(decoration: TextDecoration.underline)),
                        ),
                        TextButton(
                          onPressed: (_timeRemaining > 0 || authState.isLoading) ? null : _resendOtp,
                          style: TextButton.styleFrom(
                            foregroundColor: _timeRemaining > 0 
                                ? AppColors.textSecondary.withOpacity(0.6)
                                : AppColors.primaryButtonColor,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _timeRemaining > 0 
                                ? "Resend in ${_formatTime(_timeRemaining)}" 
                                : "Resend OTP",
                            style: TextStyle(
                              fontWeight: _timeRemaining > 0 ? FontWeight.w500 : FontWeight.w600,
                              decoration: _timeRemaining > 0 ? TextDecoration.none : TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Verify OTP Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (authState.isLoading || _otpController.text.length < 6) ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButtonColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primaryButtonColor.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    "Verify OTP",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_outline, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Signup Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.doNotHaveAccount,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Text(
                          AppStrings.signupLink,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryButtonColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryButtonColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
