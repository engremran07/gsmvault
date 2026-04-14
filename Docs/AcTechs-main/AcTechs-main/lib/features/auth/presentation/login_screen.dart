import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/providers/theme_provider.dart';
import 'package:ac_techs/core/widgets/snackbars.dart';
import 'package:ac_techs/features/auth/data/auth_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

const _kRememberEmailKey = 'remember_email';
const _kRememberMeKey = 'remember_me';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _sendingReset = false;
  bool _rememberMe = false;
  bool _capsLockOn = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_refreshCapsLockState);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadSavedCredentials(),
    );
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kRememberMeKey) ?? false;
    if (saved) {
      final email = prefs.getString(_kRememberEmailKey) ?? '';
      if (mounted) {
        setState(() {
          _rememberMe = true;
          _emailController.text = email;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode
      ..removeListener(_refreshCapsLockState)
      ..dispose();
    super.dispose();
  }

  void _refreshCapsLockState() {
    final shouldShow =
        _passwordFocusNode.hasFocus &&
        HardwareKeyboard.instance.lockModesEnabled.contains(
          KeyboardLockMode.capsLock,
        );

    if (!mounted || _capsLockOn == shouldShow) {
      return;
    }

    setState(() => _capsLockOn = shouldShow);
  }

  KeyEventResult _handlePasswordKeyEvent(FocusNode _, KeyEvent event) {
    _refreshCapsLockState();
    return KeyEventResult.ignored;
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save / clear remember me
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool(_kRememberMeKey, true);
        await prefs.setString(_kRememberEmailKey, _emailController.text.trim());
      } else {
        await prefs.remove(_kRememberMeKey);
        await prefs.remove(_kRememberEmailKey);
      }

      await ref
          .read(signInProvider.notifier)
          .signIn(_emailController.text.trim(), _passwordController.text);
      TextInput.finishAutofillContext(shouldSave: true);
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        ErrorSnackbar.show(context, message: e.message(locale));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePasswordReset() async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ErrorSnackbar.show(context, message: l.enterEmail);
      return;
    }
    if (!email.contains('@')) {
      ErrorSnackbar.show(context, message: l.enterValidEmail);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.passwordResetConfirmTitle),
        content: Text(l.passwordResetConfirmBody(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.send),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sendingReset = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined, size: 48),
          title: Text(l.passwordResetEmailSentTitle),
          content: Text(l.passwordResetEmailSentBody(email)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.confirm),
            ),
          ],
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ErrorSnackbar.show(context, message: e.message(locale));
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Language & Theme ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Language popup
                        PopupMenuButton<String>(
                          onSelected: (code) => ref
                              .read(appLocaleProvider.notifier)
                              .setLocale(code),
                          icon: const Icon(Icons.language_rounded),
                          tooltip: l.language,
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'en',
                              child: Row(
                                children: [
                                  if (locale == 'en')
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  if (locale == 'en') const SizedBox(width: 8),
                                  Text(l.english),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'ur',
                              child: Row(
                                children: [
                                  if (locale == 'ur')
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  if (locale == 'ur') const SizedBox(width: 8),
                                  Text(l.urdu),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'ar',
                              child: Row(
                                children: [
                                  if (locale == 'ar')
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  if (locale == 'ar') const SizedBox(width: 8),
                                  Text(l.arabic),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Theme popup
                        PopupMenuButton<AppThemeMode>(
                          onSelected: (mode) => ref
                              .read(appThemeModeProvider.notifier)
                              .setMode(mode),
                          icon: Icon(_themeIcon(themeMode)),
                          tooltip: l.theme,
                          itemBuilder: (_) => [
                            _themeMenuItem(
                              AppThemeMode.auto,
                              Icons.brightness_auto_rounded,
                              l.themeAuto,
                              themeMode,
                            ),
                            _themeMenuItem(
                              AppThemeMode.dark,
                              Icons.dark_mode_rounded,
                              l.themeDark,
                              themeMode,
                            ),
                            _themeMenuItem(
                              AppThemeMode.light,
                              Icons.light_mode_rounded,
                              l.themeLight,
                              themeMode,
                            ),
                            _themeMenuItem(
                              AppThemeMode.highContrast,
                              Icons.contrast_rounded,
                              l.themeHighContrast,
                              themeMode,
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),

                    // Logo
                    Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                ArcticTheme.arcticBlue,
                                ArcticTheme.arcticBlueDark,
                              ],
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: ArcticTheme.arcticBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.ac_unit_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 40,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.5, 0.5)),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      l.appName,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    const SizedBox(height: 8),
                    Text(
                      l.appSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                    const SizedBox(height: 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration: InputDecoration(
                        hintText: l.email,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l.enterEmail;
                        }
                        if (!value.contains('@')) {
                          return l.invalidEmail;
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),

                    // Password Field
                    Focus(
                      onKeyEvent: _handlePasswordKeyEvent,
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          hintText: l.password,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: ArcticTheme.arcticTextSecondary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l.enterPassword;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleSignIn(),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                    if (_capsLockOn)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_capslock_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.capsLockWarning,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 180.ms),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: (_isLoading || _sendingReset)
                            ? null
                            : _handlePasswordReset,
                        child: _sendingReset
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : Text(l.resetPassword),
                      ),
                    ).animate().fadeIn(delay: 625.ms),
                    const SizedBox(height: 12),

                    // Remember Me
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            activeColor: ArcticTheme.arcticBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Text(
                            l.rememberMe,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 650.ms),
                    const SizedBox(height: 8),
                    Text(
                      l.passwordManagerHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 675.ms),
                    const SizedBox(height: 24),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArcticTheme.arcticDarkBg,
                                ),
                              )
                            : Text(l.signIn),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _themeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.auto:
        return Icons.brightness_auto_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.highContrast:
        return Icons.contrast_rounded;
    }
  }

  PopupMenuItem<AppThemeMode> _themeMenuItem(
    AppThemeMode mode,
    IconData icon,
    String label,
    AppThemeMode current,
  ) {
    final selected = mode == current;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 8),
          Text(label),
          if (selected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
