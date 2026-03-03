import 'package:flutter/material.dart';
import '../../dashboard/widgets/home_tab_widget.dart';
import '../../schools/widgets/schools_tab_widget.dart';
import '../../dashboard/widgets/global_statistics_tab_widget.dart';
import '../../dashboard/widgets/user_settings_tab_widget.dart';
import '../widgets/dashboard_bottom_nav_bar.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTabWidget(),
    SchoolsTabWidget(),
    GlobalStatisticsTabWidget(),
    UserSettingsTabWidget(),
  ];

  final List<String> _titles = const [
    'ទំព័រដើម',
    'សាលារបស់ខ្ញុំ',
    'ស្ថិតិ',
    'ការកំណត់',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: DashboardBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
