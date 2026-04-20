import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

const Map<String, Map<String, dynamic>> cityAreaData = {
  "Delhi": {
    "name": "Delhi",
    "areas": ["North Campus", "South Campus", "Dwarka", "Rohini"],
  },
  "Mumbai": {
    "name": "Mumbai",
    "areas": ["Churchgate", "Kalina", "Powai", "Andheri"],
  },
  "Bangalore": {
    "name": "Bangalore",
    "areas": ["Malleswaram", "Koramangala", "Whitefield", "Electronic City"],
  },
  "Chennai": {
    "name": "Chennai",
    "areas": ["Guindy", "Taramani", "Adyar", "Nungambakkam"],
  },
  "Hyderabad": {
    "name": "Hyderabad",
    "areas": ["Gachibowli", "Kukatpally", "Tarnaka", "Himayatnagar"],
  },
  "Pune": {
    "name": "Pune",
    "areas": ["Shivajinagar", "Kothrud", "Hinjewadi", "Viman Nagar"],
  },
  "Kolkata": {
    "name": "Kolkata",
    "areas": ["Salt Lake", "Jadavpur", "Park Street", "Rajarhat"],
  },
  "Ahmedabad": {
    "name": "Ahmedabad",
    "areas": ["Navrangpura", "Vastrapur", "Maninagar", "Satellite"],
  },
  "Kanpur": {
    "name": "Kanpur",
    "areas": ["Kalyanpur", "Swaroop Nagar", "Civil Lines"],
  },
  "Coimbatore": {
    "name": "Coimbatore",
    "areas": ["Peelamedu", "Avinashi Road", "Gandhipuram"],
  },
  "Lucknow": {
    "name": "Lucknow",
    "areas": ["Hazratganj", "Gomti Nagar", "Aliganj", "Indira Nagar"],
  },
  "Jaipur": {
    "name": "Jaipur",
    "areas": ["Malviya Nagar", "Mansarovar", "Vaishali Nagar", "C-Scheme"],
  },
  "Indore": {
    "name": "Indore",
    "areas": ["Vijay Nagar", "Palasia", "Rajwada", "Annapurna"],
  },
  "Patna": {
    "name": "Patna",
    "areas": ["Boring Road", "Kankarbagh", "Bailey Road", "Rajendra Nagar"],
  },
  "Bhopal": {
    "name": "Bhopal",
    "areas": ["MP Nagar", "Arera Colony", "Kolar Road", "Shahpura"],
  },
  "Surat": {
    "name": "Surat",
    "areas": ["Adajan", "Vesu", "City Light", "Katargam"],
  },
  "Nagpur": {
    "name": "Nagpur",
    "areas": ["Dharampeth", "Sitabuldi", "Civil Lines", "Wardha Road"],
  },
  "Kochi": {
    "name": "Kochi",
    "areas": ["Ernakulam", "Kakkanad", "Fort Kochi", "Edappally"],
  },
  "Visakhapatnam": {
    "name": "Visakhapatnam",
    "areas": ["MVP Colony", "Dwaraka Nagar", "Gajuwaka", "Rushikonda"],
  },
  "Chandigarh": {
    "name": "Chandigarh",
    "areas": ["Sector 17", "Sector 22", "Sector 35", "Manimajra"],
  },
};

Future<void> uploadCitiesToFirestore() async {
  for (final cityKey in cityAreaData.keys) {
    final cityData = cityAreaData[cityKey]!;

    // Add city document with name field
    await firestore.collection('cities').doc(cityKey).set({
      'name': cityData['name'],
    });

    final List<String> areas = List<String>.from(cityData['areas']);
    for (final area in areas) {
      await firestore
          .collection('cities')
          .doc(cityKey)
          .collection('areas')
          .doc(area) // area used as-is (no lowercase or underscore)
          .set({'name': area});
    }
  }

  debugPrint('✅ Cities and areas uploaded without formatting.');
}
