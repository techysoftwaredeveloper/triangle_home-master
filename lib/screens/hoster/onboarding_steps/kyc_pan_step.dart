import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/document_upload.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class KycPanStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const KycPanStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<KycPanStep> createState() => _KycPanStepState();
}

class _KycPanStepState extends State<KycPanStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _panNumberController;
  String? _panUrl;

  @override
  void initState() {
    super.initState();
    _panNumberController = TextEditingController(text: widget.initialData['panNumber'] ?? '');
    _panUrl = widget.initialData['panUrl'];
  }

  @override
  void dispose() {
    _panNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PAN Card Verification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 8),
            const Text(
              'PAN is required for financial compliance and payouts.',
              style: TextStyle(color: AppTheme.textLightColor),
            ),
            const SizedBox(height: 32),
            InputField(
              label: 'PAN Number',
              controller: _panNumberController,
              required: true,
              textCapitalization: TextCapitalization.characters,
              hintText: 'ABCDE1234F',
              validator: (value) {
                if (value == null || value.isEmpty) return 'PAN number is required';
                if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.toUpperCase())) {
                  return 'Enter a valid PAN number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            RealtimeDocumentUpload(
              title: 'PAN Card Photo',
              subtitle: 'Upload the front side of your PAN',
              initialUrl: _panUrl,
              onUploadComplete: (url) => setState(() => _panUrl = url),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _panUrl != null
                  ? () {
                    if (_formKey.currentState!.validate()) {
                      widget.onContinue({
                        'panNumber': _panNumberController.text.toUpperCase(),
                        'panUrl': _panUrl,
                      });
                    }
                  }
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
