import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../core/ui/app_assets.dart';
import '../../../core/ui/widgets/app_svg_icon.dart';
import '../../../core/ui/widgets/app_gradient_background.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthMode { login, register, resetPassword }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _handledCallback = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  _AuthMode _mode = _AuthMode.login;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  void _maybeHandleOAuthRedirect(Uri uri) {
    if (_handledCallback) return;

    final qp = uri.queryParameters;
    final hasAuthParams = qp.containsKey('code') || qp.containsKey('access_token') || uri.fragment.isNotEmpty;
    if (!hasAuthParams) return;

    _handledCallback = true;
    Future.microtask(() async {
      final redirectUri = Uri(
        scheme: 'com.example.finalai',
        host: 'login-callback',
        query: uri.query,
        fragment: uri.fragment,
      );
      await ref.read(authProvider.notifier).completeOAuthRedirect(redirectUri);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _passwordController.clear();
      _confirmController.clear();
      _obscurePassword = true;
      _obscureConfirm = true;
    });
  }

  void _submit() {
    final notifier = ref.read(authProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-posta adresini gir')),
      );
      return;
    }

    if (_mode == _AuthMode.resetPassword) {
      notifier.resetPassword(email);
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreni gir')),
      );
      return;
    }

    if (_mode == _AuthMode.register) {
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre en az 6 karakter olmalı')),
        );
        return;
      }
      if (password != _confirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifreler eşleşmiyor')),
        );
        return;
      }
      notifier.signUpWithEmail(email, password);
    } else {
      notifier.signInWithEmail(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final uri = GoRouterState.of(context).uri;
    _maybeHandleOAuthRedirect(uri);

    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    final isLogin = _mode == _AuthMode.login;
    final isRegister = _mode == _AuthMode.register;
    final isReset = _mode == _AuthMode.resetPassword;

    final title = isLogin
        ? 'Hos geldin! 👋'
        : isRegister
            ? 'Hesap olustur 🚀'
            : 'Sifre sifirla 🔑';
    final subtitle = isLogin
        ? 'Devam etmek icin giris yap'
        : isRegister
            ? 'Bilgilerini gir ve hemen basla'
            : 'E-posta adresini gir, sifre sifirlama linki gonderelim';
    final buttonLabel = isLogin
        ? 'Giris yap'
        : isRegister
            ? 'Hesap olustur'
            : 'Link gonder';
    final buttonIcon = isLogin
        ? Icons.arrow_forward_rounded
        : isRegister
            ? Icons.person_add_rounded
            : Icons.send_rounded;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AppGradientBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                const SizedBox(height: 34),
                Center(
                  child: Column(
                    children: [
                      Image.asset(AppAssets.logoPng, width: 104, height: 104),
                      const SizedBox(height: 14),
                      Text(
                        'FinalAI',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Akilli calisma arkadasin',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onPrimary.withAlpha((0.92 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(_mode),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onPrimary.withAlpha((0.9 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (auth.isLoading) ...[
                  LoadingIndicator(
                    message: isRegister ? 'Hesap olusturuluyor...' : 'Giris yapiliyor...',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (auth.errorMessage != null) ...[
                  BaseCard(
                    borderColor: AppColors.error,
                    child: Text(auth.errorMessage!, style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                BaseCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _AuthInput(
                          hintText: 'E-posta',
                          icon: Icons.mail_outline,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        if (!isReset) ...[
                          const SizedBox(height: 14),
                          _AuthInput(
                            hintText: 'Sifre',
                            icon: Icons.lock_outline,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: theme.colorScheme.onSurface.withAlpha((0.55 * 255).round()),
                              ),
                            ),
                          ),
                        ],
                        if (isRegister) ...[
                          const SizedBox(height: 14),
                          _AuthInput(
                            hintText: 'Sifre tekrar',
                            icon: Icons.lock_outline,
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: theme.colorScheme.onSurface.withAlpha((0.55 * 255).round()),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ExpressiveButton(
                          onPressed: auth.isLoading ? null : _submit,
                          height: 56,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          borderRadius: AppRadius.xl,
                          child: Row(
                            children: [
                              const SizedBox(width: 18),
                              Expanded(
                                child: Text(
                                  buttonLabel,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Icon(buttonIcon, size: 22),
                              const SizedBox(width: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isReset) ...[
                  const SizedBox(height: 18),
                  ExpressiveButton(
                    onPressed: auth.isLoading ? null : () => ref.read(authProvider.notifier).signInWithGoogle(),
                    height: 56,
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    borderRadius: AppRadius.xl,
                    borderSide: BorderSide(color: theme.dividerColor, width: 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppSvgIcon(AppAssets.brandGoogle, size: 20, useThemeColorIfNull: false),
                        const SizedBox(width: 12),
                        Text(
                          isLogin ? 'Google ile giris yap' : 'Google ile kayit ol',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (isLogin)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _AuthFooterAction(
                          icon: Icons.person_add_alt_1_outlined,
                          label: 'Hesap olustur',
                          onTap: () => _switchMode(_AuthMode.register),
                        ),
                        const SizedBox(width: 12),
                        _AuthFooterAction(
                          icon: Icons.lock_reset_outlined,
                          label: 'Sifremi unuttum',
                          onTap: () => _switchMode(_AuthMode.resetPassword),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: _AuthFooterAction(
                      icon: Icons.arrow_back_rounded,
                      label: 'Girise don',
                      onTap: () => _switchMode(_AuthMode.login),
                    ),
                  ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  const _AuthInput({
    required this.hintText,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.colorScheme.surface.withAlpha((0.78 * 255).round());
    final border = theme.dividerColor.withAlpha((0.6 * 255).round());

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.18 * 255).round()),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha((0.42 * 255).round()),
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null) ...[
            SizedBox(width: 44, child: Center(child: suffix)),
            const SizedBox(width: 6),
          ] else ...[
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _AuthFooterAction extends StatelessWidget {
  const _AuthFooterAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.18 * 255).round()),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 18, color: onPrimary),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
