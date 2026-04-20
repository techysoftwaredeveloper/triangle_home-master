import 'package:flutter/material.dart';
import '../utils/upload_states.dart';

class AdminToolsScreen extends StatelessWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Tools")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await uploadCitiesToFirestore();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data uploaded to Firestore!')),
            );
          },
          child: const Text("Upload States & Cities"),
        ),
      ),
    );
  }
}
