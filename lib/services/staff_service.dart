import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/models/staff_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triangle_home/models/user.dart' as model;

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all staff assignments for a property
  Stream<List<HostAssignment>> getPropertyStaff(String propertyId) {
    return _firestore
        .collection('hostAssignments')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HostAssignment.fromFirestore(doc)).toList());
  }

  /// Get all staff members with user profiles for a property
  Stream<List<StaffMember>> getPropertyStaffMembers(String propertyId) {
    return getPropertyStaff(propertyId).switchMap((assignments) {
      if (assignments.isEmpty) return Stream.value([]);

      final userIds = assignments.map((a) => a.userId).where((id) => id.isNotEmpty).toSet().toList();
      if (userIds.isEmpty) return Stream.value([]);

      // Fetch users in chunks of 10 (Firestore limit for 'whereIn')
      final userStreams = <Stream<List<model.User>>>[];
      for (var i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10);
        if (chunk.isEmpty) continue; // Ensure chunk is not empty

        userStreams.add(
          _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .snapshots()
              .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                return model.User(
                  id: doc.id,
                  phoneNumber: data['phone'] ?? data['phoneNumber'] ?? '',
                  email: data['email'],
                  name: data['info']?['name'] ?? data['name'],
                  profilePicture: data['info']?['profileImage'] ?? data['profilePicture'],
                  createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                );
              }).toList()),
        );
      }

      return Rx.combineLatest<List<model.User>, List<model.User>>(
        userStreams,
        (lists) => lists.expand((list) => list).toList(),
      ).map((users) {
        final userMap = {for (var u in users) u.id: u};
        return assignments
            .map((a) => StaffMember(
                  assignment: a,
                  user: userMap[a.userId] ??
                      model.User(
                        id: a.userId,
                        phoneNumber: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        name: 'Unknown User',
                      ),
                ))
            .toList();
      });
    });
  }

  /// Get pending invitations for a property
  Stream<List<HostInvitation>> getPropertyInvitations(String propertyId) {
    return _firestore
        .collection('hostInvitations')
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HostInvitation.fromFirestore(doc)).toList());
  }

  /// Get real-time activity feed for a property
  Stream<List<StaffActivity>> getPropertyActivity(String propertyId) {
    return _firestore
        .collection('hostActivities')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => StaffActivity.fromFirestore(doc)).toList());
  }

  /// Calculate real-time staff KPIs for a property
  Stream<Map<String, dynamic>> getStaffKPIs(String propertyId) {
    return Rx.combineLatest2(
      getPropertyStaff(propertyId),
      getPropertyInvitations(propertyId),
      (staff, invitations) {
        final totalHosts = staff.length;
        final primaryHosts = staff.where((s) => s.role == StaffRole.primaryHost).length;
        final assistantHosts = staff.where((s) => s.role == StaffRole.assistantHost).length;
        final activePermissions = staff.fold<int>(0, (acc, s) => acc + s.permissions.length);
        final pendingInvitations = invitations.length;

        return {
          'totalHosts': totalHosts,
          'primaryHosts': primaryHosts,
          'assistantHosts': assistantHosts,
          'activePermissions': activePermissions,
          'pendingInvitations': pendingInvitations,
        };
      },
    );
  }

  /// Invite a new host to a property
  Future<void> inviteHost({
    required String propertyId,
    required String email,
    String? phone,
    required StaffRole role,
    required String invitedBy,
  }) async {
    final docRef = _firestore.collection('hostInvitations').doc();
    final invitation = HostInvitation(
      id: docRef.id,
      propertyId: propertyId,
      email: email,
      phone: phone,
      role: role,
      status: InvitationStatus.pending,
      sentAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      invitedBy: invitedBy,
    );

    await docRef.set(invitation.toFirestore());
  }

  /// Log a staff action
  Future<void> logActivity({
    required String hostId,
    required String propertyId,
    required String actionType,
    required String entityType,
    required String entityId,
    required String description,
  }) async {
    await _firestore.collection('hostActivities').add({
      'hostId': hostId,
      'propertyId': propertyId,
      'actionType': actionType,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Update staff permissions
  Future<void> updatePermissions(String assignmentId, List<String> permissions) async {
    await _firestore.collection('hostAssignments').doc(assignmentId).update({
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Suspend or deactivate a staff member
  Future<void> updateStaffStatus(String assignmentId, StaffStatus status) async {
    await _firestore.collection('hostAssignments').doc(assignmentId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
