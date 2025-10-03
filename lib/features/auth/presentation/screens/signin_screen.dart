import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/validation_constants.dart';
import '../../../../shared/widgets/forms/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes for proper focus management
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  bool _showSignUpSuggestion = false;
  bool _showPasswordResetSuggestion = false;

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

    // Log screen view
    FirebaseAnalyticsService().logScreenView(
      screenName: 'SignIn',
      screenClass: 'SignInScreen',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
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

  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
      _showSignUpSuggestion = false;
      _showPasswordResetSuggestion = false;
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

    // Log sign in attempt
    await FirebaseAnalyticsService().logSignInAttempt();

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            email: email,
            password: password,
          );

      if (mounted) {
        // Clear the password only on successful login for security
        _passwordController.clear();

        // Invalidate organizations to ensure fresh data
        ref.invalidate(userOrganizationsProvider);

        // Wait for organizations to load
        try {
          final organizations = await ref.read(userOrganizationsProvider.future);

          if (mounted) {
            final hasOrganization = organizations.isNotEmpty;

            // Log successful sign in
            final user = ref.read(authControllerProvider).value;
            if (user != null) {
              await FirebaseAnalyticsService().logSignInSuccess(
                method: 'email',
                hasOrganization: hasOrganization,
              );
              await FirebaseAnalyticsService().setUserId(user.id);
              await FirebaseAnalyticsService().setUserProperty(
                name: 'has_organization',
                value: hasOrganization ? 'true' : 'false',
              );
              await FirebaseAnalyticsService().setUserProperty(
                name: 'user_type',
                value: 'registered',
              );
              await FirebaseAnalyticsService().setUserProperty(
                name: 'auth_method',
                value: 'email',
              );
            }

            if (hasOrganization) {
              // Has organizations, go to dashboard
              context.go('/dashboard');
            } else {
              // No organizations, go to create
              context.go('/organization/create');
            }
          }
        } catch (e) {
          // If error loading organizations, go to dashboard anyway
          if (mounted) {
            // Log success even if org check failed
            final user = ref.read(authControllerProvider).value;
            if (user != null) {
              await FirebaseAnalyticsService().logSignInSuccess(
                method: 'email',
                hasOrganization: false,
              );
              await FirebaseAnalyticsService().setUserId(user.id);
            }
            context.go('/dashboard');
          }
        }
      }
    } catch (e) {
      // Log sign in failure
      String errorType = 'other';

      setState(() {
        if (e is AuthInvalidCredentialsError) {
          errorType = 'invalid_credentials';
          _errorMessage = 'We couldn\'t sign you in with these credentials.';
          _showSignUpSuggestion = true;
          _showPasswordResetSuggestion = true;
        } else {
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('invalid login credentials') ||
              errorString.contains('invalid password') ||
              errorString.contains('user not found')) {
            errorType = 'invalid_credentials';
            _errorMessage = 'We couldn\'t sign you in with these credentials.';
            _showSignUpSuggestion = true;
            _showPasswordResetSuggestion = true;
          } else if (errorString.contains('email not confirmed')) {
            errorType = 'email_not_confirmed';
            _errorMessage = 'Please verify your email before signing in';
            _showPasswordResetSuggestion = false;
            _showSignUpSuggestion = false;
          } else if (errorString.contains('too many requests')) {
            errorType = 'too_many_requests';
            _errorMessage = 'Too many attempts. Please try again later';
            _showPasswordResetSuggestion = false;
            _showSignUpSuggestion = false;
          } else if (errorString.contains('network') ||
              errorString.contains('connection')) {
            errorType = 'network';
            _errorMessage = 'Network error. Please check your connection';
            _showPasswordResetSuggestion = false;
            _showSignUpSuggestion = false;
          } else {
            errorType = 'other';
            _errorMessage = 'Failed to sign in. Please try again';
            _showPasswordResetSuggestion = false;
            _showSignUpSuggestion = false;
          }
        }
      });

      await FirebaseAnalyticsService().logSignInFailed(errorType: errorType);
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
                            padding: EdgeInsets.only(bottom: isSmallScreen ? 24 : 32),
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
                                SizedBox(height: isSmallScreen ? 20 : 24),
                                Text(
                                  'Welcome back',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: isMobile ? 24 : isTablet ? 26 : 28,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue to TellMeMo',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Error message with animations
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
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
                                        if (_showSignUpSuggestion || _showPasswordResetSuggestion) ...[
                                          const SizedBox(height: 12),
                                          Divider(
                                            color: colorScheme.error.withOpacity(0.1),
                                          ),
                                          const SizedBox(height: 8),
                                          if (_showSignUpSuggestion) ...[
                                            InkWell(
                                              onTap: _isLoading
                                                  ? null
                                                  : () {
                                                      context.push(
                                                        '/auth/signup?email=${Uri.encodeComponent(_emailController.text.trim())}',
                                                      );
                                                    },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 32,
                                                  vertical: 4,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person_add_outlined,
                                                      color: colorScheme.primary,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'New user? Create an account',
                                                      style: textTheme.bodySmall?.copyWith(
                                                        color: colorScheme.primary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (_showPasswordResetSuggestion)
                                              const SizedBox(height: 4),
                                          ],
                                          if (_showPasswordResetSuggestion) ...[
                                            InkWell(
                                              onTap: _isLoading
                                                  ? null
                                                  : () {
                                                      context.push(
                                                        '/auth/forgot-password?email=${Uri.encodeComponent(_emailController.text.trim())}',
                                                      );
                                                    },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 32,
                                                  vertical: 4,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.lock_reset_outlined,
                                                      color: colorScheme.primary,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Forgot password? Reset it',
                                                      style: textTheme.bodySmall?.copyWith(
                                                        color: colorScheme.primary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Email field with label
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
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                validator: FormValidators.validateEmail,
                                enabled: !_isLoading,
                                onSubmitted: (_) {
                                  // If password is already filled, sign in. Otherwise move focus to password field
                                  if (_passwordController.text.isNotEmpty && !_isLoading) {
                                    _handleSignIn();
                                  } else {
                                    _passwordFocusNode.requestFocus();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Password field with label
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
                                hintText: '••••••••',
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                                onSubmitted: (_) {
                                  // Trigger sign-in when pressing Enter on password field
                                  if (!_isLoading) {
                                    _handleSignIn();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Remember me and Forgot password - responsive layout
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runAlignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              InkWell(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _rememberMe = !_rememberMe;
                                        });
                                      },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: _isLoading
                                              ? null
                                              : (value) {
                                                  setState(() {
                                                    _rememberMe = value ?? false;
                                                  });
                                                },
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember me',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: isMobile ? 14 : 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        final email = _emailController.text.trim();
                                        if (email.isNotEmpty) {
                                          context.push('/auth/forgot-password?email=${Uri.encodeComponent(email)}');
                                        } else {
                                          context.push('/auth/forgot-password');
                                        }
                                      },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 14 : 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Sign In button with loading state
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: FilledButton(
                              onPressed: _isLoading ? null : _handleSignIn,
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
                                            'Signing in...',
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 16,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        key: const ValueKey('signin'),
                                        'Sign In',
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

                          // Divider with "OR"
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

                          // Sign up link section
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
                                  "Don't have an account? ",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: isMobile ? 14 : 15,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          final email = _emailController.text.trim();
                                          if (email.isNotEmpty) {
                                            context.push('/auth/signup?email=${Uri.encodeComponent(email)}');
                                          } else {
                                            context.push('/auth/signup');
                                          }
                                        },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Create account',
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
      ),
    );
  }
}