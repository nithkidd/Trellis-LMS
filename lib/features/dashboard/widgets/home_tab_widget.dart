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
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'សូមស្វាគមន៍មកវិញ!',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'នេះជាទិដ្ឋភាពសង្ខេបសម្រាប់ថ្ងៃនេះ។',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('សកម្មភាពរហ័ស', style: AppTextStyles.subheading),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Text(
                'សូមទៅកាន់ផ្ទាំងសាលាខាងក្រោម\nដើម្បីគ្រប់គ្រងថ្នាក់ និងពិន្ទុ។',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
