import 'package:triangle_home/core/constants/enums.dart';

class PermissionService {
  static const Map<UserRole, List<String>> _rolePermissions = {
    UserRole.admin: [
      'manage_users',
      'approve_listings',
      'view_audit_logs',
      'run_reconciliation',
      'manage_payments',
      'export_data',
    ],
    UserRole.hoster: [
      'create_listing',
      'update_listing',
      'approve_booking',
      'view_property_stats',
      'manage_own_bookings',
    ],
    UserRole.student: [
      'search_properties',
      'request_booking',
      'view_own_bookings',
      'make_payment',
      'write_review',
    ],
    UserRole.guest: [
      'search_properties',
    ],
  };

  static bool hasPermission(UserRole role, String permission) {
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  static List<String> getPermissions(UserRole role) {
    return _rolePermissions[role] ?? [];
  }
}
