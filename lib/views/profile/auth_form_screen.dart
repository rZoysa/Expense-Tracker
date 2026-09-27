import 'package:expense_tracker/viewmodels/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

enum AuthFormMode { createAccount, signIn }

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({required this.mode, super.key});

  final AuthFormMode mode;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isCreatingAccount => widget.mode == AuthFormMode.createAccount;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email address.';
    }

    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter your password.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isCreatingAccount) {
      return null;
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    final wasSuccessful = _isCreatingAccount
        ? await authViewModel.createAccount(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await authViewModel.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!mounted || !wasSuccessful) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreatingAccount ? 'Create account' : 'Sign in'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _isCreatingAccount
                      ? Icons.person_add_alt_1_outlined
                      : Icons.login_outlined,
                  size: 56.r,
                  color: colorScheme.primary,
                ),
                SizedBox(height: 16.h),
                Text(
                  _isCreatingAccount
                      ? 'Keep your current expenses'
                      : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8.h),
                Text(
                  _isCreatingAccount
                      ? 'Your guest account will be upgraded to email/password sign-in without changing your Firebase user ID.'
                      : 'Sign in to access the expenses saved under your existing account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!_isCreatingAccount) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20.r,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'Signing into an existing account switches away from this guest session. Guest expenses are not merged automatically.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 28.h),
                TextFormField(
                  controller: _emailController,
                  enabled: !authViewModel.isProcessing,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _passwordController,
                  enabled: !authViewModel.isProcessing,
                  obscureText: _obscurePassword,
                  textInputAction: _isCreatingAccount
                      ? TextInputAction.next
                      : TextInputAction.done,
                  autofillHints: _isCreatingAccount
                      ? const [AutofillHints.newPassword]
                      : const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: authViewModel.isProcessing
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                  onFieldSubmitted: _isCreatingAccount
                      ? null
                      : (_) => _submit(),
                ),
                if (_isCreatingAccount) ...[
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !authViewModel.isProcessing,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: authViewModel.isProcessing
                            ? null
                            : () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: _validateConfirmPassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
                if (authViewModel.errorMessage != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      authViewModel.errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
                SizedBox(height: 24.h),
                FilledButton(
                  onPressed: authViewModel.isProcessing ? null : _submit,
                  child: authViewModel.isProcessing
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isCreatingAccount ? 'Create Account' : 'Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
