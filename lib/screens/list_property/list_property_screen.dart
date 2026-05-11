import 'package:flutter/material.dart';
import 'package:triangle_home/screens/list_property/banking_info_screen.dart';
import 'package:triangle_home/screens/list_property/basic_info_screen.dart';
import 'package:triangle_home/screens/list_property/pricing_info_screen.dart';
import 'package:triangle_home/screens/list_property/property_info_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/progress_bar.dart';

class ListPropertyScreen extends StatefulWidget {
  const ListPropertyScreen({super.key});

  @override
  State<ListPropertyScreen> createState() => _ListPropertyScreenState();
}

class _ListPropertyScreenState extends State<ListPropertyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<String, dynamic> _propertyData = {};

  void _nextPage(Map<String, dynamic> data) {
    setState(() {
      _propertyData.addAll(data);
      if (_currentPage < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDarkColor, size: 20),
          onPressed: _previousPage,
        ),
        title: const Text(
          'List Your Property',
          style: TextStyle(
            color: AppTheme.textDarkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ),
      body: Column(
        children: [
          ProgressBar(currentStep: _currentPage),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                BasicInfoScreen(onContinue: _nextPage),
                BankingInfoScreen(onContinue: _nextPage),
                PropertyInfoScreen(onContinue: _nextPage),
                PricingInfoScreen(onContinue: (data) {
                  // Final submission logic handled in PricingInfoScreen
                }, propertyData: _propertyData),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
