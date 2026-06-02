import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/screens/admin/admin_login_screen.dart';
import 'package:triangle_home/screens/auth/otp_verification_screen.dart';
import 'package:triangle_home/screens/hoster/become_hoster_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/screens/list_property/intro_screen.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/widgets/social_buttons.dart';

class LoginScreen extends StatefulWidget {
  final bool isStudent;
  final Widget? onLoginNavigateTo;
  //const LoginScreen({super.key, required Null Function() onVerificationComplete});
  const LoginScreen({
    super.key,
    required this.isStudent,
    this.onLoginNavigateTo,
  });
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  bool _isLoading = false;
  int _logoTapCount = 0;

  // Static instance to prevent multiple initialization issues
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final List<String> _studentContent = [
    'Apartments? PG Accommodations? We\'ve got you!',
    'Find your perfect home away from home',
    'Easy booking process with secure payments',
    'Verified listings with real photos and reviews',
  ];

  final List<String> _hosterContent = [
    'List your property & reach thousands of students',
    'Manage bookings effortlessly in one place',
    'Fast payouts & secure business growth',
    'Verified tenants for your peace of mind',
  ];

  List<String> get _contentItems => widget.isStudent ? _studentContent : _hosterContent;

  Color get _themeColor => widget.isStudent ? AppTheme.primaryColor : AppTheme.successColor;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    // Rebuild when phone field changes so button reactive state updates
    _phoneController.addListener(() => setState(() {}));
    
    // Save onboarding intent based on mode
    _saveIntent();
  }

  void _saveIntent() async {
    await IsarService().setUserIntent(widget.isStudent ? 'student' : 'hoster');
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

  Future<void> _handleSocialLogin(String provider) async {
    if (provider != 'Google') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$provider login coming soon')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ 1. Trigger Google Sign-In flow
      // NOTE: Ensure SHA-1 & SHA-256 fingerprints are added to Firebase Console.
      // NOTE: Ensure Google Sign-In is enabled in Firebase Authentication methods.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the selection
        setState(() => _isLoading = false);
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      
      final User? user = userCredential.user;
      if (user == null) throw Exception('Firebase User is null after successful Google Sign-In');

      if (!mounted) return;

      final uid = user.uid;
      final String email = user.email ?? '';
      final String displayName = user.displayName ?? '';

      // Sync user data with Firestore
      final DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Create new user profile
        await userRef.set({
          'role': widget.isStudent ? 'student' : 'hoster',
          'info': {
            'name': displayName,
            'email': email,
            'profileImage': user.photoURL,
            'phoneNumber': user.phoneNumber,
          },
          'permissions': {
            'is_admin': false,
          },
          'is_active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Update existing user's last login
        await userRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      // Determine the destination screen based on user role and context
      if (!widget.isStudent) {
        // Hoster Flow
        final userData = userDoc.exists ? (userDoc.data() as Map<String, dynamic>) : null;
        final bool isAlreadyHoster = userData != null && userData['role'] == 'hoster';

        if (isAlreadyHoster) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HosterDashboardScreen()),
            (route) => false,
          );
        } else {
          // If they chose "List Your Property" but are a new user or not yet marked as hoster
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BecomeHosterScreen()),
            (route) => false,
          );
        }
      } else {
        // Student/Guest Flow
        if (widget.onLoginNavigateTo != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => widget.onLoginNavigateTo!),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Google Login Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to login with Google: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          // Let main.dart handle navigation
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          String message = e.message ?? 'Verification failed';
          
          if (e.code == 'too-many-requests') {
            message = 'Too many requests. Please try again later.';
          } else if (e.code == 'invalid-phone-number') {
            message = 'The provided phone number is not valid.';
          } else if (e.toString().contains('reCAPTCHA')) {
            message = 'Safety check failed. Please ensure you are not on a VPN and have Google Play Services updated.';
            debugPrint('🛡️ ReCAPTCHA Error Detail: ${e.toString()}');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) async {
          if (!mounted) return;
          // Navigate, then stop loading
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => OtpVerificationScreen(
                    verificationId: verificationId,
                    phoneNumber: _phoneController.text,
                    isStudent: widget.isStudent,
                    onLoginNavigateTo: widget.onLoginNavigateTo,
                  ),
            ),
          );
          if (!mounted) return;
          setState(() => _isLoading = false); // Stop loading after returning
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('An error occurred')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              // No gap — white sheet starts flush with header (matches Figma)
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      color: _themeColor,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _logoTapCount++);
              if (_logoTapCount >= 7) {
                _logoTapCount = 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/Logo.svg',
                  height: 32,
                  width: 32,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TRIANGLE HOMES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'outfit',
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms),

          const SizedBox(height: 24),

          _buildCarousel(),

          const SizedBox(height: 12),

          SmoothPageIndicator(
            controller: _pageController,
            count: _contentItems.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 7,
              dotWidth: 7,
              activeDotColor: Colors.white,
              dotColor: Colors.white38,
              spacing: 6,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 800.ms),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
          height: 44,
          width: double.maxFinite,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _contentItems.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Small icon inside pill (matches Figma pill design)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        widget.isStudent ? Icons.home_outlined : Icons.business_center_outlined,
                        size: 14,
                        color: _themeColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _contentItems[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'outfit',
                          color: _themeColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 800.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        // Light grey background matching actual screen (not pure white)
        color: Color(0xFFF5F6FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome!',
              style: TextStyle(
                fontSize: AppTheme.font2XL,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textColor,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            const Text(
              'Please enter your phone number:',
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                fontWeight: FontWeight.normal,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textLightColor,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 20),

            TextFormField(
              maxLength: 10,
              textAlign: TextAlign.left,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '10 Digit Phone Number',
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _themeColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length != 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            const Text(
              'Or Login/Signup Using A Social Account:',
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                color: AppTheme.textLightColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 16),

            SocialLoginButtons(
              onGoogleTap: () => _handleSocialLogin('Google'),
              onFacebookTap: () => _handleSocialLogin('Facebook'),
              onAppleTap: () => _handleSocialLogin('Apple'),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_isLoading || _phoneController.text.length < 10)
                        ? null
                        : _verifyPhone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  disabledForegroundColor: AppTheme.textMutedColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: AppTheme.fontMD,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                if (widget.isStudent) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListPropertyIntroScreen(
                        onGetStarted: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen(isStudent: false)),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
              child: Text(
                widget.isStudent ? 'Are you a property owner? Join us' : 'Forgot Password?',
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ).animate().fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }
}
