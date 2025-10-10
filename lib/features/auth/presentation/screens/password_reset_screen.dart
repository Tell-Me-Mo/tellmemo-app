import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/validation_constants.dart';
import '../../../../shared/widgets/forms/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../../core/services/notification_service.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  final String? token;

  const PasswordResetScreen({super.key, this.token});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordsMatch = true;

  @override
  void initState() {
    super.initState();
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

    // Add listeners for password matching
    _passwordController.addListener(_checkPasswordMatch);
    _confirmPasswordController.addListener(_checkPasswordMatch);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _checkPasswordMatch() {
    if (_confirmPasswordController.text.isNotEmpty) {
      setState(() {
        _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
      });
    }
  }

  double _getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return 450;
    } else if (screenWidth >= 600) {
      return 420;
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

  Future<void> _handlePasswordUpdate() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).updatePassword(
            _passwordController.text,
          );

      if (mounted) {
        // Show success message and navigate to sign in
        ref.read(notificationServiceProvider.notifier).showSuccess('Password updated successfully! Please sign in with your new password.');
        context.go('/auth/signin');
      }
    } catch (e) {
      setState(() {
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('invalid token') ||
            errorString.contains('expired')) {
          _errorMessage = 'This reset link has expired. Please request a new one.';
        } else if (errorString.contains('weak password')) {
          _errorMessage = 'Password is too weak. Please use a stronger password';
        } else if (errorString.contains('network') ||
            errorString.contains('connection')) {
          _errorMessage = 'Network error. Please check your connection';
        } else {
          _errorMessage = 'Failed to reset password. Please try again';
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

  bool _isPasswordValid() {
    final password = _passwordController.text;
    return password.length >= 6;
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isMet ? Colors.green : colorScheme.onSurfaceVariant,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 800;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    final password = _passwordController.text;
    final hasMinLength = password.length >= 6;

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
                          // Logo and Title Section
                          Container(
                            padding: EdgeInsets.only(bottom: isSmallScreen ? 20 : 28),
                            child: Column(
                              children: [
                                Container(
                                  width: isMobile ? 60 : isTablet ? 64 : 72,
                                  height: isMobile ? 60 : isTablet ? 64 : 72,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.primary.withOpacity(0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.lock_reset_outlined,
                                    size: isMobile ? 34 : isTablet ? 36 : 40,
                                    color: colorScheme.surface,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                Text(
                                  'Create new password',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: isMobile ? 24 : isTablet ? 26 : 28,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your new password must be different from previous passwords',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // Error message
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _errorMessage != null ? null : 0,
                            child: _errorMessage != null
                                ? Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.error.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: colorScheme.error.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.info_outline_rounded,
                                            size: 18,
                                            color: colorScheme.error,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // New Password field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Password',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: _passwordController,
                                hintText: 'Create a strong password',
                                obscureText: !_isPasswordVisible,
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                validator: FormValidators.validatePassword,
                                enabled: !_isLoading,
                                autofocus: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirm Password',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: _confirmPasswordController,
                                hintText: 'Re-enter your password',
                                obscureText: !_isConfirmPasswordVisible,
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: !_passwordsMatch && _confirmPasswordController.text.isNotEmpty
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                                validator: (value) => FormValidators.validateConfirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                                enabled: !_isLoading,
                              ),
                            ],
                          ),

                          // Password requirements with live validation
                          if (password.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isPasswordValid()
                                      ? Colors.green.withOpacity(0.3)
                                      : colorScheme.outlineVariant.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password strength',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPasswordRequirement('At least 6 characters', hasMinLength),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),

                          // Reset password button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: FilledButton(
                              onPressed: _isLoading ? null : _handlePasswordUpdate,
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
                                            'Resetting password...',
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 16,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        key: const ValueKey('reset'),
                                        'Reset Password',
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 24),

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
                          SizedBox(height: isMobile ? 20 : 24),

                          // Cancel link
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
                                    Icons.close_rounded,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cancel and return to Sign In',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
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
      ),
    );
  }
}