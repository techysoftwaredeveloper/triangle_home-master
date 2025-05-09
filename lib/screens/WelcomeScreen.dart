// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// import 'package:triangle_home/screens/OtpVerificationScreen.dart';
// import 'package:triangle_home/widgets/accommodation_search.dart';
// import 'package:triangle_home/widgets/logo.dart';
// import 'package:triangle_home/widgets/phone_input.dart';
// import 'package:triangle_home/widgets/social_buttons.dart';


// class WelcomeScreen extends StatefulWidget {
//   const WelcomeScreen({super.key});

//   @override
//   State<WelcomeScreen> createState() => _WelcomeScreenState();
// }

// class _WelcomeScreenState extends State<WelcomeScreen> {
//   final CarouselController _carouselController = CarouselController();
//   int _currentCarouselIndex = 0;
//   final TextEditingController _phoneController = TextEditingController();
  
//   final List<String> _carouselItems = [
//     // 'Apartments? PG Accommodations? We\'ve got you!',
//     'Eacy and securly manage properties in ease',
//     'Find your perfect home away from home',
//     'Easy booking process with secure payments',
//     'Verified listings with real photos and reviews',
//   ];

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   void _handleGetStarted() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OtpVerificationScreen(
//           phoneNumber: "98972 36559",
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//              const SizedBox(height: 40),
//             Expanded(child: _buildContent()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//       color: Theme.of(context).primaryColor,
//       child: Column(
//         children: [
//           // App Logo and Brand
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               TriangleLogo(),
//               SizedBox(width: 12),
//               Text(
//                 'T R I A N G L E  H O M E S',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 1.5,
//                 ),
//               ),
//             ],
//           ).animate().fadeIn(duration: 800.ms),
          
//           const SizedBox(height: 80),
          
//           // Search Bar
//           AccommodationSearch(
//             items: _carouselItems,
//             controller: _carouselController,
//             currentIndex: _currentCarouselIndex,
//           )
//           .animate()
//           .fadeIn(delay: 300.ms, duration: 800.ms)
//           .slideY(begin: -0.2, end: 0),
          
//           const SizedBox(height: 8),
          
//           // Carousel Indicator
//           AnimatedSmoothIndicator(
//             activeIndex: _currentCarouselIndex,
//             count: _carouselItems.length,
//             effect: const ExpandingDotsEffect(
//               dotHeight: 8,
//               dotWidth: 8,
//               activeDotColor: Colors.white,
//               dotColor: Colors.white54,
//               spacing: 6,
//             ),
//           ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent() {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(32),
//           topRight: Radius.circular(32),
//         ),
//       ),
//       padding: const EdgeInsets.all(24),
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const SizedBox(height: 8),
//             Text(
//               'Welcome!',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
//             const SizedBox(height: 16),
//             const Text(
//               'Please enter your phone number:',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Color(0xFF6B7280),
//               ),
//             ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
//             const SizedBox(height: 24),
            
//             // Phone Input
//             const PhoneInput()
//               .animate()
//               .fadeIn(delay: 500.ms)
//               .slideY(begin: 0.2, end: 0),
            
//             const SizedBox(height: 32),
            
//             // Social Login Options
//             const Text(
//               'Or Login/Signup Using A Social Account:',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Color(0xFF6B7280),
//               ),
//             ).animate().fadeIn(delay: 600.ms),
            
//             const SizedBox(height: 16),
            
//             // Social Login Buttons
//             const SocialLoginButtons()
//               .animate()
//               .fadeIn(delay: 700.ms)
//               .slideY(begin: 0.2, end: 0),
            
//             const SizedBox(height: 32),
            
//             // Get Started Button
//             ElevatedButton(
//               onPressed: _handleGetStarted,
//               child: const Text('Get Started'),
//             ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
            
//             const SizedBox(height: 16),
            
//             // Forgot Password Link
//             TextButton(
//               onPressed: () {},
//               child: const Text(
//                 'Forgot Password?',
//                 style: TextStyle(
//                   color: Color(0xFF3B82F6),
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ).animate().fadeIn(delay: 900.ms),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:triangle_home/screens/OtpVerificationScreen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/phone_input.dart';
import 'package:triangle_home/widgets/social_buttons.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _phoneController = TextEditingController();
  
  final List<String> _contentItems = [
    'Apartments? PG Accommodations? We\'ve got you!',
    'Find your perfect home away from home',
    'Easy booking process with secure payments',
    'Verified listings with real photos and reviews',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final nextPage = (_currentPage + 1) % _contentItems.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  void _handleGetStarted() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          phoneNumber: _phoneController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
             const SizedBox(height: 30),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          // App Logo and Brand

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

            const SizedBox(height: 80),
              //TriangleLogo(),
              Image.asset(
                'assets/images/logomain.png',
                height: 50,
                width: 50,            
              ),
              const SizedBox(width: 10),
              Text(
                'T R I A N G L E  H O M E S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'outfit',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 800.ms),
          
          const SizedBox(height: 20),
          
          // Content Slider
          SizedBox(
            height: 40,
            width: double.maxFinite,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _contentItems.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _contentItems[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        //fontWeight: FontWeight,
                        fontFamily: 'outfit',
                        color: const Color.fromRGBO(49, 78, 125, 100),

                      ),
                    ),
                  ),
                );
              },
            ),
          ).animate()
            .fadeIn(delay: 300.ms, duration: 800.ms)
            .slideY(begin: -0.2, end: 0),
          
          const SizedBox(height: 8),
          
          // Page Indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: _contentItems.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: Colors.white,
              dotColor: Colors.white54,
              spacing: 6,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(
              'Welcome!',
              style:TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                fontFamily: 'outfit',
                color:  Colors.grey[800],
              )
             // style: Theme.of(context).textTheme.headlineMedium,

            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            const Text(
              'Please enter your phone number:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                fontFamily: 'outfit',
                color: Color(0xFF6B7280),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 24),
            
            // Phone Input
            const PhoneInput()
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            // Social Login Options
            const Text(
              'Or Login/Signup Using A Social Account:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ).animate().fadeIn(delay: 600.ms),
            
            const SizedBox(height: 16),
            
            // Social Login Buttons
            const SocialLoginButtons()
              .animate()
              .fadeIn(delay: 700.ms)
              .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            // Get Started Button
            ElevatedButton(
              onPressed: _handleGetStarted,
              child: const Text('Get Started'),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 16),
            
            // Forgot Password Link
            TextButton(
              onPressed: () {},
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate().fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }
}