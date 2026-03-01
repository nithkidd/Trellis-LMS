import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HomeTabWidget extends StatelessWidget {
  const HomeTabWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Here is your overview for today.',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Quick Actions', style: AppTextStyles.subheading),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Text(
                'Navigate to the Schools tab below\nto manage your classes and grading.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
