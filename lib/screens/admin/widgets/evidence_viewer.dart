import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/models/dispute.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EvidenceViewer extends StatelessWidget {
  final List<DisputeEvidence> evidence;

  const EvidenceViewer({super.key, required this.evidence});

  @override
  Widget build(BuildContext context) {
    if (evidence.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.attachment_rounded, color: Colors.grey[300], size: 40),
              const SizedBox(height: 12),
              Text(
                'No evidence uploaded',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: evidence.length,
      itemBuilder: (context, index) {
        return _EvidenceItem(item: evidence[index]);
      },
    );
  }
}

class _EvidenceItem extends StatelessWidget {
  final DisputeEvidence item;

  const _EvidenceItem({required this.item});

  void _openFile(BuildContext context) async {
    final type = item.fileType.toLowerCase();
    if (type == 'image') {
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  CachedNetworkImage(imageUrl: item.url, fit: BoxFit.contain),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
      );
    } else {
      // For PDF/Video, try to launch URL
      final uri = Uri.parse(item.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open file')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData typeIcon = Icons.insert_drive_file_rounded;
    Color typeColor = Colors.grey;

    if (item.fileType.contains('image')) {
      typeIcon = Icons.image_rounded;
      typeColor = Colors.blue;
    } else if (item.fileType.contains('pdf')) {
      typeIcon = Icons.picture_as_pdf_rounded;
      typeColor = Colors.red;
    } else if (item.fileType.contains('video')) {
      typeIcon = Icons.videocam_rounded;
      typeColor = Colors.purple;
    }

    return InkWell(
      onTap: () => _openFile(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child:
                    item.fileType == 'image'
                        ? CachedNetworkImage(
                          imageUrl: item.url,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  Container(color: Colors.grey[50]),
                        )
                        : Container(
                          width: double.infinity,
                          color: typeColor.withValues(alpha: 0.1),
                          child: Icon(typeIcon, color: typeColor, size: 32),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uploaded by ${item.uploadedBy.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 8,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM, hh:mm a').format(item.timestamp),
                        style: TextStyle(fontSize: 8, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
