
import 'package:flutter/material.dart';

class ImageUploadWidget extends StatelessWidget {
  final List<String> uploadedImages;
  final Function(int) onImageRemoved;
  final VoidCallback onRemoveAll;

  const ImageUploadWidget({
    super.key,
    required this.uploadedImages,
    required this.onImageRemoved,
    required this.onRemoveAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uploaded Images (${uploadedImages.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: onRemoveAll,
                child: const Text(
                  'Remove All',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: uploadedImages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(uploadedImages[index]),
                          Text(
                            '1.27 MB',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onImageRemoved(index),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              // Handle image upload
            },
            icon: const Icon(Icons.upload),
            label: const Text('Upload More'),
          ),
          const SizedBox(height: 4),
          Text(
            'JPEG, PNG, PDF',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
