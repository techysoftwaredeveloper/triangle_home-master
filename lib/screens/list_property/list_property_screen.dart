import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/screens/list_property/banking_info_screen.dart';
import 'package:triangle_home/screens/list_property/basic_info_screen.dart';
import 'package:triangle_home/screens/list_property/pricing_info_screen.dart';
import 'package:triangle_home/screens/list_property/property_info_screen.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
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
    _propertyData.addAll(data);
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _previousPage,
        ),
        title: const Text(
          'List My Property',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
                PropertyInfoScreen(onContinue: (data) => _nextPage(data)),
                PricingInfoScreen(
                  onContinue: (data) async {
                    _propertyData.addAll(data);
                    try {
                      // add property to database
                      await FirebaseFirestore.instance
                          .collection('properties')
                          .add(_propertyData);

                      if (mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Property listed successfully!'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'An error occurred while listing the property: $e',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 3),
    );
  }
}
