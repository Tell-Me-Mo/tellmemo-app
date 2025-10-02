import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/validation_constants.dart';
import '../../../../shared/widgets/forms/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if provided
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double _getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return 450;
    } else if (screenWidth >= 600) {
      return 400;
    } else {
      return screenWidth * 0.9;
    }
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    } else if (screenWidth >= 600) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  Future<void> _handlePasswordReset() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            _emailController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _emailSent = true;
          _successMessage = 'Password reset email sent successfully!';
        });
      }
    } catch (e) {
      setState(() {
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('user not found') ||
            errorString.contains('no user found')) {
          _errorMessage = 'No account found with this email address';
        } else if (errorString.contains('invalid email')) {
          _errorMessage = 'Please enter a valid email address';
        } else if (errorString.contains('too many requests')) {
          _errorMessage = 'Too many requests. Please try again later';
        } else if (errorString.contains('network') ||
            errorString.contains('connection')) {
          _errorMessage = 'Network error. Please check your connection';
        } else {
          _errorMessage = 'Failed to send reset email. Please try again';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.primary.withOpacity(0.03),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 12 : 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          context.pop();
                        } else {
                          context.go('/auth/signin');
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Reset Password',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: _getResponsivePadding(context),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: _getResponsiveWidth(context),
                          padding: EdgeInsets.all(
                            isMobile ? 24 : isTablet ? 32 : 40,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.04),
                                blurRadius: 40,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.01),
                                blurRadius: 60,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Icon and Title Section
                                Container(
                                  padding: EdgeInsets.only(bottom: isSmallScreen ? 24 : 32),
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        width: isMobile ? 60 : isTablet ? 64 : 72,
                                        height: isMobile ? 60 : isTablet ? 64 : 72,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: _emailSent
                                                ? [
                                                    Colors.green,
                                                    Colors.green.withOpacity(0.85),
                                                  ]
                                                : [
                                                    colorScheme.primary,
                                                    colorScheme.primary.withOpacity(0.85),
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _emailSent
                                                  ? Colors.green.withOpacity(0.3)
                                                  : colorScheme.primary.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: Icon(
                                            _emailSent
                                                ? Icons.mark_email_read_outlined
                                                : Icons.lock_reset_outlined,
                                            key: ValueKey(_emailSent),
                                            size: isMobile ? 34 : isTablet ? 36 : 40,
                                            color: colorScheme.surface,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 20 : 24),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: Text(
                                          _emailSent ? 'Check your email' : 'Forgot password?',
                                          key: ValueKey(_emailSent),
                                          style: textTheme.headlineMedium?.copyWith(
                                            fontSize: isMobile ? 24 : isTablet ? 26 : 28,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSurface,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: Text(
                                          _emailSent
                                              ? "We've sent instructions to reset your password"
                                              : "No worries, we'll send you reset instructions",
                                          key: ValueKey(_emailSent),
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: isMobile ? 14 : 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Error/Success Messages
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: _errorMessage != null || _successMessage != null ? null : 0,
                                  child: (_errorMessage != null || _successMessage != null)
                                      ? Container(
                                          margin: const EdgeInsets.only(bottom: 20),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: _successMessage != null
                                                ? Colors.green.withOpacity(0.1)
                                                : colorScheme.errorContainer.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _successMessage != null
                                                  ? Colors.green.withOpacity(0.2)
                                                  : colorScheme.error.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: _successMessage != null
                                                      ? Colors.green.withOpacity(0.1)
                                                      : colorScheme.error.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  _successMessage != null
                                                      ? Icons.check_circle_outline_rounded
                                                      : Icons.info_outline_rounded,
                                                  size: 18,
                                                  color: _successMessage != null
                                                      ? Colors.green
                                                      : colorScheme.error,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _successMessage ?? _errorMessage!,
                                                  style: textTheme.bodyMedium?.copyWith(
                                                    color: _successMessage != null
                                                        ? Colors.green.shade700
                                                        : colorScheme.error,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),

                                // Content based on state
                                AnimatedCrossFade(
                                  firstChild: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Email field
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Email',
                                            style: textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          AppTextField(
                                            controller: _emailController,
                                            hintText: 'you@example.com',
                                            keyboardType: TextInputType.emailAddress,
                                            prefixIcon: Icon(
                                              Icons.mail_outline_rounded,
                                              color: colorScheme.onSurfaceVariant,
                                              size: 20,
                                            ),
                                            validator: FormValidators.validateEmail,
                                            enabled: !_isLoading,
                                            autofocus: _emailController.text.isEmpty,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),

                                      // Send reset email button
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        child: FilledButton(
                                          onPressed: _isLoading ? null : _handlePasswordReset,
                                          style: FilledButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              vertical: isMobile ? 14 : 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: _isLoading ? 0 : 1,
                                            backgroundColor: colorScheme.primary,
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            child: _isLoading
                                                ? Row(
                                                    key: const ValueKey('loading'),
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          valueColor: AlwaysStoppedAnimation(
                                                            colorScheme.onPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        'Sending...',
                                                        style: TextStyle(
                                                          fontSize: isMobile ? 14 : 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: colorScheme.onPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    key: const ValueKey('send'),
                                                    'Send Reset Email',
                                                    style: TextStyle(
                                                      fontSize: isMobile ? 14 : 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: colorScheme.onPrimary,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  secondChild: Column(
                                    children: [
                                      // Email sent instructions
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: colorScheme.primary.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              color: colorScheme.primary,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'We sent an email to',
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _emailController.text.trim(),
                                              style: textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Please check your inbox and click the reset link. '
                                              'The link will expire in 1 hour.',
                                              textAlign: TextAlign.center,
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Resend email button
                                      OutlinedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                setState(() {
                                                  _emailSent = false;
                                                  _successMessage = null;
                                                });
                                              },
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: isMobile ? 12 : 14,
                                            horizontal: 24,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          side: BorderSide(
                                            color: colorScheme.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          'Try Another Email',
                                          style: TextStyle(
                                            fontSize: isMobile ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  crossFadeState: !_emailSent
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  duration: const Duration(milliseconds: 300),
                                ),

                                SizedBox(height: isMobile ? 24 : 32),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: colorScheme.outlineVariant.withOpacity(0.3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: colorScheme.outlineVariant.withOpacity(0.3),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Back to sign in
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLowest.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => context.go('/auth/signin'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_back_rounded,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Back to Sign In',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: isMobile ? 14 : 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}