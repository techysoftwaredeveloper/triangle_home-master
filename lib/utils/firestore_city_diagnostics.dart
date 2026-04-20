import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/utils/upload_states.dart';

/// Diagnostic tool to check and fix Firestore cities collection
class FirestoreCityDiagnostics {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if cities exist in Firestore
  static Future<void> checkCities() async {
    debugPrint('🔍 Checking Firestore cities collection...');
    
    try {
      final snapshot = await _firestore.collection('cities').get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No cities found in Firestore!');
        debugPrint('📝 Please run: await uploadCitiesToFirestore()');
        return;
      }
      
      debugPrint('✅ Found ${snapshot.docs.length} cities');
      debugPrint('─' * 50);
      
      for (final doc in snapshot.docs) {
        final name = doc['name'] ?? 'NO NAME FIELD';
        debugPrint('📍 Document ID: ${doc.id}');
        debugPrint('   Name: $name');
        
        // Check if areas subcollection exists
        final areasSnapshot = await doc.reference.collection('areas').get();
        debugPrint('   Areas: ${areasSnapshot.docs.length} areas');
        
        if (areasSnapshot.docs.isNotEmpty) {
          final areaNames = areasSnapshot.docs.map((a) => a.id).take(3).join(', ');
          debugPrint('   Sample areas: $areaNames...');
        }
        debugPrint('─' * 50);
      }
    } catch (e) {
      debugPrint('❌ Error checking cities: $e');
    }
  }

  /// Upload cities if they don't exist
  static Future<void> ensureCitiesExist() async {
    debugPrint('🔧 Ensuring cities exist in Firestore...');
    
    final snapshot = await _firestore.collection('cities').get();
    
    if (snapshot.docs.isEmpty) {
      debugPrint('📤 Cities not found. Uploading now...');
      await uploadCitiesToFirestore();
      debugPrint('✅ Cities uploaded successfully!');
    } else {
      debugPrint('✅ Cities already exist (${snapshot.docs.length} cities)');
    }
  }

  /// Fix mismatched document IDs and name fields
  static Future<void> fixCityMappings() async {
    debugPrint('🔧 Fixing city document mappings...');
    
    try {
      final snapshot = await _firestore.collection('cities').get();
      int fixed = 0;
      
      for (final doc in snapshot.docs) {
        final name = doc['name'] as String?;
        
        // If name field doesn't match document ID, update it
        if (name != null && name != doc.id) {
          debugPrint('⚠️ Mismatch: ID="${doc.id}", Name="$name"');
          await doc.reference.update({'name': doc.id});
          fixed++;
        }
      }
      
      if (fixed > 0) {
        debugPrint('✅ Fixed $fixed city mappings');
      } else {
        debugPrint('✅ All city mappings are correct');
      }
    } catch (e) {
      debugPrint('❌ Error fixing mappings: $e');
    }
  }

  /// Test city lookup (simulates what the app does)
  static Future<void> testCityLookup(String testCity) async {
    debugPrint('🧪 Testing city lookup for: "$testCity"');
    
    try {
      final snapshot = await _firestore.collection('cities').get();
      
      // Test case-insensitive matching
      String? matchedCity;
      for (final doc in snapshot.docs) {
        final cityName = doc['name'].toString();
        if (cityName.toLowerCase() == testCity.toLowerCase()) {
          matchedCity = cityName;
          break;
        }
      }
      
      if (matchedCity != null) {
        debugPrint('✅ Found match: "$matchedCity"');
      } else {
        debugPrint('❌ No match found for "$testCity"');
        debugPrint('   Available cities:');
        for (final doc in snapshot.docs) {
          debugPrint('   - ${doc['name']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error testing lookup: $e');
    }
  }
}
