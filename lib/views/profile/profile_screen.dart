import 'package:expense_tracker/viewmodels/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final isAnonymous = authViewModel.isAnonymous;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAnonymous
                    ? Icons.account_circle_outlined
                    : Icons.verified_user_outlined,
                size: 64.r,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 16.h),
              Text(
                isAnonymous
                    ? 'Guest account'
                    : authViewModel.email ?? 'Signed-in account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Text(
                isAnonymous
                    ? 'Your expenses are stored under a temporary Firebase account. '
                          'You will be able to link an email and password here without losing your data.'
                    : 'Your account is connected to Firebase Authentication.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
