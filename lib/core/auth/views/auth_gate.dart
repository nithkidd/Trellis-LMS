import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dashboard/views/main_dashboard_screen.dart';
import '../../../splash_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/functional_minimalism_widgets.dart';
import '../providers/auth_providers.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (error, _) => _AuthStatusScreen(
        title: 'Authentication is unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
      ),
      data: (user) {
        if (user == null) {
          return const SignInScreen();
        }

        final profileState = ref.watch(userProfileProvider(user.uid));
        return profileState.when(
          loading: () => const SplashScreen(),
          error: (error, _) => _AuthStatusScreen(
            title: 'Unable to load account access',
            message: '$error',
            icon: Icons.error_outline_rounded,
            actionLabel: 'Sign out',
            onAction: () => ref.read(authServiceProvider).signOut(),
          ),
          data: (profile) {
            if (profile == null) {
              return _AuthStatusScreen(
                title: 'Account created, access not finished',
                message:
                    'This sign-in worked, but there is no Trellis profile document for this account yet. Create a Firestore document in "${AuthService.userProfilesCollection}/{uid}" before granting access.',
                icon: Icons.pending_actions_rounded,
                actionLabel: 'Sign out',
                onAction: () => ref.read(authServiceProvider).signOut(),
                footer: 'Signed in as ${user.email ?? user.uid}',
                uid: user.uid,
              );
            }

            if (!profile.isActive) {
              return _AuthStatusScreen(
                title: profile.isDeclined
                    ? 'This access request was declined'
                    : profile.isPendingApproval
                    ? 'This access request is pending approval'
                    : 'This account is currently inactive',
                message: profile.isDeclined
                    ? 'An administrator reviewed this request and declined access. Contact your organization if you need them to review it again.'
                    : profile.isPendingApproval
                    ? 'Your account request was created successfully, but access stays off until an administrator approves it and links the teacher record.'
                    : 'The account exists, but access has been turned off. Ask your administrator to reactivate it.',
                icon: profile.isDeclined
                    ? Icons.cancel_outlined
                    : profile.isPendingApproval
                    ? Icons.pending_actions_rounded
                    : Icons.lock_outline_rounded,
                actionLabel: 'Sign out',
                onAction: () => ref.read(authServiceProvider).signOut(),
                footer: profile.email,
              );
            }

            return const MainDashboardScreen();
          },
        );
      },
    );
  }
}

class _AuthStatusScreen extends StatelessWidget {
  const _AuthStatusScreen({
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.footer,
    this.uid,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final String? footer;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: TrellisSectionSurface(
                padding: const EdgeInsets.all(AppSizes.paddingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrellisAccentIcon(
                      accent: TrellisAccentPalette.warning(icon: icon),
                      size: 64,
                      iconSize: 30,
                    ),
                    const SizedBox(height: AppSizes.paddingLg),
                    Text(title, style: AppTextStyles.heading),
                    const SizedBox(height: AppSizes.paddingSm),
                    Text(
                      message,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (uid != null) ...[
                      const SizedBox(height: AppSizes.paddingMd),
                      SelectableText('UID: $uid', style: AppTextStyles.caption),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: AppSizes.paddingMd),
                      Text(footer!, style: AppTextStyles.caption),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: AppSizes.paddingLg),
                      FilledButton(
                        onPressed: () => onAction!(),
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
