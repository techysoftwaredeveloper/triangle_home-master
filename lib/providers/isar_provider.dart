import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/services/isar_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});
