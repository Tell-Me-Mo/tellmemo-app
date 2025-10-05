import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/validation_constants.dart';
import '../../../../shared/widgets/forms/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const SignUpScreen({
    super.key,
    this.initialEmail,
  });

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes for proper focus management
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

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
    // Pre-fill email if provided
    final hasPrefilledEmail = widget.initialEmail != null && widget.initialEmail!.isNotEmpty;
    if (hasPrefilledEmail) {
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

    // Add listeners for password matching
    _passwordController.addListener(_checkPasswordMatch);
    _confirmPasswordController.addListener(_checkPasswordMatch);

    // Log screen view and form started
    FirebaseAnalyticsService().logScreenView(
      screenName: 'SignUp',
      screenClass: 'SignUpScreen',
    );
    FirebaseAnalyticsService().logSignUpFormStarted(
      hasPrefilledEmail: hasPrefilledEmail,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
      return 500;
    } else if (screenWidth >= 600) {
      return 450;
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

  Future<void> _handleSignUp() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Store the values to ensure they persist
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final hasName = name.isNotEmpty;

    // Log signup attempt
    await FirebaseAnalyticsService().logSignUpAttempt();

    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: email,
            password: password,
            name: hasName ? name : null,
          );

      if (mounted) {
        // Clear sensitive data only on successful signup
        _passwordController.clear();
        _confirmPasswordController.clear();

        // Check if user has any organizations
        try {
          final organizations = await ref.read(userOrganizationsProvider.future);

          if (mounted) {
            final willCreateOrg = organizations.isEmpty;

            // Log successful signup
            final user = ref.read(authControllerProvider).value;
            if (user != null) {
              await FirebaseAnalyticsService().logSignUpSuccess(
                hasName: hasName,
                willCreateOrg: willCreateOrg,
              );
              await FirebaseAnalyticsService().setUserId(user.id);
              await FirebaseAnalyticsService().setUserProperty(
                name: 'has_organization',
                value: (!willCreateOrg).toString(),
              );
            }

            if (organizations.isNotEmpty) {
              // User has organizations (e.g., was invited), go to dashboard
              context.go('/dashboard');
            } else {
              // New user without organizations, go to organization creation
              context.go('/organization/create');
            }
          }
        } catch (e) {
          // If there's an error checking organizations, let auth guard handle it
          if (mounted) {
            // Log success even if org check failed
            final user = ref.read(authControllerProvider).value;
            if (user != null) {
              await FirebaseAnalyticsService().logSignUpSuccess(
                hasName: hasName,
                willCreateOrg: true,
              );
              await FirebaseAnalyticsService().setUserId(user.id);
              await FirebaseAnalyticsService().setUserProperty(
                name: 'user_type',
                value: 'registered',
              );
              await FirebaseAnalyticsService().setUserProperty(
                name: 'auth_method',
                value: 'email',
              );
              await FirebaseAnalyticsService().setUserProperty(
                name: 'has_organization',
                value: 'false',
              );
            }
            context.go('/dashboard');
          }
        }
      }
    } catch (e) {
      // Log signup failure
      String errorType = 'other';

      setState(() {
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('email already registered') ||
            errorString.contains('user already registered') ||
            errorString.contains('email already exists') ||
            errorString.contains('duplicate')) {
          errorType = 'email_exists';
          _errorMessage = 'email_exists';  // Special flag for existing email
        } else if (errorString.contains('invalid email')) {
          errorType = 'invalid_email';
          _errorMessage = 'Please enter a valid email address';
        } else if (errorString.contains('weak password')) {
          errorType = 'weak_password';
          _errorMessage = 'Password is too weak. Please use a stronger password';
        } else if (errorString.contains('network') ||
            errorString.contains('connection')) {
          errorType = 'network';
          _errorMessage = 'Network error. Please check your connection';
        } else {
          errorType = 'other';
          _errorMessage = 'Failed to create account. Please try again';
        }
        _isLoading = false;
      });

      await FirebaseAnalyticsService().logSignUpFailed(errorType: errorType);
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
          child: Column(
            children: [
              // Custom AppBar with back button
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
                        'Create Account',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to balance the back button
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
                                    Icons.hub_outlined,
                                    size: isMobile ? 34 : isTablet ? 36 : 40,
                                    color: colorScheme.surface,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                Text(
                                  'Welcome to TellMeMo',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: isMobile ? 24 : isTablet ? 26 : 28,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Join us to start managing your projects',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
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
                                          child: _errorMessage == 'email_exists'
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'An account with this email already exists',
                                                      style: textTheme.bodyMedium?.copyWith(
                                                        color: colorScheme.error,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    InkWell(
                                                      onTap: () {
                                                        // Navigate to sign in with the email
                                                        context.push(
                                                          '/auth/signin',
                                                        );
                                                      },
                                                      child: Text(
                                                        'Sign in instead →',
                                                        style: textTheme.bodySmall?.copyWith(
                                                          color: colorScheme.primary,
                                                          fontWeight: FontWeight.w600,
                                                          decoration: TextDecoration.underline,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
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

                          // Name field (optional)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Full Name',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(optional)',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                hintText: 'John Doe',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                enabled: !_isLoading,
                                onSubmitted: (_) {
                                  // Move to next field or submit if all fields are filled
                                  if (_emailController.text.isNotEmpty &&
                                      _passwordController.text.isNotEmpty &&
                                      _confirmPasswordController.text.isNotEmpty &&
                                      !_isLoading) {
                                    _handleSignUp();
                                  } else {
                                    // Explicitly move focus to email field
                                    _emailFocusNode.requestFocus();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

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
                                focusNode: _emailFocusNode,
                                hintText: 'you@example.com',
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: FormValidators.validateRequiredEmail,
                                enabled: !_isLoading,
                                onSubmitted: (_) {
                                  // Move to next field or submit if all fields are filled
                                  if (_passwordController.text.isNotEmpty &&
                                      _confirmPasswordController.text.isNotEmpty &&
                                      !_isLoading) {
                                    _handleSignUp();
                                  } else {
                                    // Explicitly move focus to password field
                                    _passwordFocusNode.requestFocus();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Password field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                hintText: 'Create a strong password',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                obscureText: !_isPasswordVisible,
                                validator: FormValidators.validatePassword,
                                enabled: !_isLoading,
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
                                onSubmitted: (_) {
                                  // Move to next field or submit if confirm password is filled
                                  if (_confirmPasswordController.text.isNotEmpty && !_isLoading) {
                                    _handleSignUp();
                                  } else {
                                    // Explicitly move focus to confirm password field
                                    _confirmPasswordFocusNode.requestFocus();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Confirm password field
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
                                focusNode: _confirmPasswordFocusNode,
                                hintText: 'Re-enter your password',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: !_passwordsMatch && _confirmPasswordController.text.isNotEmpty
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                obscureText: !_isConfirmPasswordVisible,
                                validator: (value) => FormValidators.validateConfirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                                enabled: !_isLoading,
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
                                onSubmitted: (_) {
                                  // Always trigger sign up when pressing Enter on confirm password
                                  if (!_isLoading) {
                                    _handleSignUp();
                                  }
                                },
                              ),
                            ],
                          ),

                          // Password requirements with live validation - only show missing requirements
                          if (password.isNotEmpty && !_isPasswordValid()) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password must include:',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Only show requirements that are not met
                                  if (!hasMinLength)
                                    _buildPasswordRequirement('At least 6 characters', false),
                                ],
                              ),
                            ),
                          ] else if (password.isNotEmpty && _isPasswordValid()) ...[
                            // Show success message when password is valid
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Password strength: Strong',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),

                          // Sign up button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: FilledButton(
                              onPressed: _isLoading ? null : _handleSignUp,
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
                                            'Creating account...',
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 16,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        key: const ValueKey('signup'),
                                        'Create Account',
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

                          // Sign in link
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: isMobile ? 14 : 15,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          context.go('/auth/signin');
                                        },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Sign in',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isMobile ? 14 : 15,
                                    ),
                                  ),
                                ),
                              ],
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