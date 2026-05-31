import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onAppleTap;

  const SocialLoginButtons({
    super.key,
    this.onGoogleTap,
    this.onFacebookTap,
    this.onAppleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          context: context,
          icon: const FaIcon(
            FontAwesomeIcons.facebook,
            color: Color(0xFF1877F2),
          ),
          onPressed: onFacebookTap ?? () {},
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          context: context,
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Image.asset(
                'assets/images/google-login.png',
                height: 50,
                width: 50,
              ),
            ),
          ),
          onPressed: onGoogleTap ?? () {},
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          context: context,
          icon: const FaIcon(
            FontAwesomeIcons.apple,
            color: Colors.black,
          ),
          onPressed: onAppleTap ?? () {},
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Center(child: icon),
      ),
    ).animate()
      .scaleXY(begin: 1, end: 0.95, duration: 100.ms)
      .then(delay: 50.ms)
      .scaleXY(begin: 0.95, end: 1, duration: 150.ms)
      .then()
      .callback(
        callback: (_) => {},
        //triggerOnce: true,
        delay: 50.ms,
      );
  }
}
