import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/wishlist/wishlist_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          user == null
              ? _buildEmptyState('Please login to view your wishlist')
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseService().getWishlist(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _buildEmptyState('Your wishlist is empty');
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final propertyData =
                          data['propertyData'] as Map<String, dynamic>? ?? {};

                      // Merge wishlist data with property data
                      final item = {
                        'id': doc.id,
                        'propertyId': data['propertyId'],
                        ...propertyData,
                      };

                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await FirebaseService().removeFromWishlist(doc.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from wishlist'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: WishlistCard(item: item).animate().fadeIn(
                          delay: Duration(milliseconds: 100 * index),
                        ),
                      );
                    },
                  );
                },
              ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontFamily: 'outfit',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
