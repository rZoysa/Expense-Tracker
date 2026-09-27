import 'package:expense_tracker/viewmodels/auth_view_model.dart';
import 'package:expense_tracker/views/profile/auth_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openAuthForm(BuildContext context, AuthFormMode mode) async {
    context.read<AuthViewModel>().clearError();

    final wasSuccessful = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => AuthFormScreen(mode: mode)));

    if (!context.mounted || wasSuccessful != true) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            mode == AuthFormMode.createAccount
                ? 'Account created successfully.'
                : 'Signed in successfully.',
          ),
        ),
      );
  }

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will continue with a new guest session. Sign in again later to access the expenses saved to this account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !context.mounted) {
      return;
    }

    final wasSuccessful = await context.read<AuthViewModel>().signOutToGuest();

    if (!context.mounted) {
      return;
    }

    if (wasSuccessful) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Signed out. Continuing as guest.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: authViewModel.isAnonymous
            ? _GuestProfile(
                isProcessing: authViewModel.isProcessing,
                onCreateAccount: () =>
                    _openAuthForm(context, AuthFormMode.createAccount),
                onSignIn: () => _openAuthForm(context, AuthFormMode.signIn),
              )
            : _SignedInProfile(
                email: authViewModel.email,
                isProcessing: authViewModel.isProcessing,
                onSignOut: () => _signOut(context),
              ),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({
    required this.isProcessing,
    required this.onCreateAccount,
    required this.onSignIn,
  });

  final bool isProcessing;
  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36.r,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: Icon(Icons.person_outline, size: 36.r),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Guest account',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'You can use the full expense tracker without creating an account. Create one when you want to keep access to this guest data across future sessions.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          FilledButton.icon(
            onPressed: isProcessing ? null : onCreateAccount,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Create Account'),
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : onSignIn,
            icon: const Icon(Icons.login_outlined),
            label: const Text('Sign In'),
          ),
          SizedBox(height: 12.h),
          Text(
            'Creating an account keeps this guest session and its expenses. Signing into an existing account switches to that account instead.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile({
    required this.email,
    required this.isProcessing,
    required this.onSignOut,
  });

  final String? email;
  final bool isProcessing;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36.r,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: Icon(Icons.verified_user_outlined, size: 34.r),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    email ?? 'Signed-in account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your account is connected to Firebase Authentication.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Account details',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(email ?? 'Not available'),
          ),
          const Divider(),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : onSignOut,
            icon: isProcessing
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
