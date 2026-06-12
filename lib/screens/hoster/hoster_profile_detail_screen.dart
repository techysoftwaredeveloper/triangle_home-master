import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';


// ── Section identifiers ───────────────────────────────────────────────────────
enum HosterProfileSection {
  basicInfo,
  identity,
  business,
  banking,
  propertySummary,
  performance,
  reviews,
  trustScore,
  preferences,
  emergency,
  security,
  notifications,
}

class HosterProfileDetailScreen extends StatefulWidget {
  final HosterProfileSection section;
  final Map<String, dynamic> stats;

  const HosterProfileDetailScreen({
    super.key,
    required this.section,
    required this.stats,
  });

  @override
  State<HosterProfileDetailScreen> createState() =>
      _HosterProfileDetailScreenState();
}

class _HosterProfileDetailScreenState
    extends State<HosterProfileDetailScreen> {
  static const _green = Color(0xFF1B4332);
  static const _greenLight = Color(0xFFDCFCE7);
  static const _verified = Color(0xFF16A34A);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);
  static const _blue = Color(0xFF3B82F6);
  static const _text = Color(0xFF1E293B);
  static const _sub = Color(0xFF64748B);
  static const _muted = Color(0xFF94A3B8);
  static const _border = Color(0xFFF1F5F9);
  static const _bg = Color(0xFFF8FAFC);

  late Stream<Map<String, dynamic>> _statsStream;
  late Map<String, dynamic> _localStats;

  @override
  void initState() {
    super.initState();
    _localStats = Map<String, dynamic>.from(widget.stats);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _statsStream = HosterService().getDetailedHosterStatsStream(uid);
    } else {
      _statsStream = Stream.value(widget.stats);
    }
  }

  Map<String, dynamic> get s => _localStats;

  String get _title {
    switch (widget.section) {
      case HosterProfileSection.basicInfo:
        return 'Basic Information';
      case HosterProfileSection.identity:
        return 'Identity & Compliance';
      case HosterProfileSection.business:
        return 'Business Information';
      case HosterProfileSection.banking:
        return 'Banking & Payouts';
      case HosterProfileSection.propertySummary:
        return 'Property Summary';
      case HosterProfileSection.performance:
        return 'Performance';
      case HosterProfileSection.reviews:
        return 'Reviews & Ratings';
      case HosterProfileSection.trustScore:
        return 'Trust Score';
      case HosterProfileSection.preferences:
        return 'Preferences';
      case HosterProfileSection.emergency:
        return 'Emergency Contact';
      case HosterProfileSection.security:
        return 'Security Center';
      case HosterProfileSection.notifications:
        return 'Notification Settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _statsStream,
      initialData: _localStats,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _localStats = snapshot.data!;
        }
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              _title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              if (_hasEditAction)
                TextButton(
                  onPressed: _onEdit,
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: _buildBody(),
          ),
        );
      },
    );
  }

  bool get _hasEditAction => [
        HosterProfileSection.basicInfo,
        HosterProfileSection.banking,
        HosterProfileSection.preferences,
        HosterProfileSection.emergency,
        HosterProfileSection.business,
      ].contains(widget.section);

  void _onEdit() {
    switch (widget.section) {
      case HosterProfileSection.basicInfo:
        _showEditBasicInfoSheet();
        break;
      case HosterProfileSection.banking:
        _showEditBankingSheet();
        break;
      case HosterProfileSection.preferences:
        _showEditPreferencesSheet();
        break;
      case HosterProfileSection.emergency:
        _showEditEmergencySheet();
        break;
      case HosterProfileSection.business:
        _showEditBusinessSheet();
        break;
      default:
        break;
    }
  }

  void _showEditBusinessSheet() {
    String selectedRole = s['hosterRole']?.toString() ?? 'Individual Owner';
    if (selectedRole.isEmpty) selectedRole = 'Individual Owner';
    String selectedExp = s['experience']?.toString() ?? '3-5 Years';
    if (selectedExp.isEmpty) selectedExp = '3-5 Years';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Business Info',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _text)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Host Type / Role',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Individual Owner', 'Company', 'Property Manager', 'Partner Hoster']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => selectedRole = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedExp,
                      decoration: const InputDecoration(
                        labelText: 'Experience',
                        border: OutlineInputBorder(),
                      ),
                      items: ['1-2 Years', '3-5 Years', '5+ Years']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => selectedExp = v);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                              'hosterRole': selectedRole,
                              'experience': selectedExp,
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Business info updated!')),
                              );
                            }
                          }
                        },
                        child: const Text('Save Changes',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBasicInfoSheet() {
    final nameController = TextEditingController(text: s['hosterName'] ?? '');
    String selectedGender = s['gender']?.toString() ?? 'Male';
    if (!['Male', 'Female', 'Other'].contains(selectedGender)) {
      selectedGender = 'Male';
    }
    DateTime? dobDate;
    if (s['dob'] != null && s['dob'].toString().isNotEmpty) {
      dobDate = DateTime.tryParse(s['dob'].toString());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Basic Info',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _text)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => selectedGender = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dobDate ?? DateTime(1995),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setSheetState(() => dobDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          dobDate != null
                              ? DateFormat('dd MMM yyyy').format(dobDate!)
                              : 'Select Date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                              'info.name': nameController.text.trim(),
                              'info.gender': selectedGender,
                              'info.dob': dobDate?.toIso8601String(),
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Basic info updated!')),
                              );
                            }
                          }
                        },
                        child: const Text('Save Changes',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBankingSheet() {
    final bankNameController = TextEditingController(text: s['bankName'] ?? '');
    final accNoController = TextEditingController(text: s['bankAccountNo'] ?? '');
    final ifscController = TextEditingController(text: s['bankIfsc'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Banking & Payouts',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _text)),
                const SizedBox(height: 16),
                TextField(
                  controller: bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accNoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ifscController,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                          'bank_info.bankName': bankNameController.text.trim(),
                          'bank_info.accountNumber': accNoController.text.trim(),
                          'bank_info.ifsc': ifscController.text.trim(),
                          'bank_info.verified': true,
                          'bank_info.upiVerified': true,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Banking details updated!')),
                          );
                        }
                      }
                    },
                    child: const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPreferencesSheet() {
    String bookingType = s['prefBookingType']?.toString() ?? 'Approval Required';
    if (bookingType.isEmpty) bookingType = 'Approval Required';
    String gender = s['prefGender']?.toString() ?? 'Any';
    if (gender.isEmpty) gender = 'Any';
    String duration = s['prefDuration']?.toString() ?? 'Any';
    if (duration.isEmpty) duration = 'Any';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Preferences',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _text)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: bookingType,
                      decoration: const InputDecoration(
                        labelText: 'Booking Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Instant Book', 'Approval Required']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => bookingType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Male', 'Female', 'Any']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => gender = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: duration,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Duration',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Long Term', 'Short Term', 'Any']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => duration = v);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                              'host_preferences.bookingType': bookingType,
                              'host_preferences.preferredGender': gender,
                              'host_preferences.preferredDuration': duration,
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Preferences updated!')),
                              );
                            }
                          }
                        },
                        child: const Text('Save Changes',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditEmergencySheet() {
    final nameController = TextEditingController(text: s['emergencyContactName'] ?? '');
    final phoneController = TextEditingController(text: s['emergencyContactPhone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Emergency Contact',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _text)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                          'emergency_contact.name': nameController.text.trim(),
                          'emergency_contact.phone': phoneController.text.trim(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Emergency contact updated!')),
                          );
                        }
                      }
                    },
                    child: const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickEmergencyContact() async {
    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        final contact = await FlutterContacts.native.showPicker(
          properties: {ContactProperty.phone},
        );
        if (contact != null) {
          // Get the first phone number and sanitize it
          final phone = contact.phones.isNotEmpty 
              ? contact.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '') 
              : '';
          final name = contact.displayName;

          if (phone.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected contact has no phone number')),
              );
            }
            return;
          }

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'emergency_contact': {
                'name': name,
                'phone': phone,
                'updatedAt': FieldValue.serverTimestamp(),
              },
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency contact updated!')),
              );
            }
          }
        }
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text('Contact permission is needed to pick an emergency contact. Please enable it in settings.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: () => openAppSettings(), child: const Text('Open Settings')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking contact: $e')),
        );
      }
    }
  }

  Widget _buildBody() {
    switch (widget.section) {
      case HosterProfileSection.basicInfo:
        return _basicInfoBody();
      case HosterProfileSection.identity:
        return _identityBody();
      case HosterProfileSection.business:
        return _businessBody();
      case HosterProfileSection.banking:
        return _bankingBody();
      case HosterProfileSection.propertySummary:
        return _propertySummaryBody();
      case HosterProfileSection.performance:
        return _performanceBody();
      case HosterProfileSection.reviews:
        return _reviewsBody();
      case HosterProfileSection.trustScore:
        return _trustScoreBody();
      case HosterProfileSection.preferences:
        return _preferencesBody();
      case HosterProfileSection.emergency:
        return _emergencyBody();
      case HosterProfileSection.security:
        return _securityBody();
      case HosterProfileSection.notifications:
        return _notificationsBody();
    }
  }

  // ────────────────────────────────────────────────────────────
  // 1. BASIC INFORMATION
  // ────────────────────────────────────────────────────────────
  Widget _basicInfoBody() {
    final name = s['hosterName'] ?? '—';
    final gender = s['gender']?.toString() ?? '';
    final dob = s['dob']?.toString() ?? '';
    final phone = s['phone']?.toString() ?? '';
    final email = s['email']?.toString() ?? '';
    final address = s['address']?.toString() ?? '';
    final city = s['city']?.toString() ?? '';
    final state = s['state']?.toString() ?? '';
    final fullAddress = [address, city, state]
        .where((v) => v.isNotEmpty)
        .join(', ');

    return Column(
      children: [
        _sectionCard(
          title: 'Basic Information',
          child: Column(
            children: [
              _infoRow(Icons.person_outline_rounded, _verified, name),
              if (gender.isNotEmpty || dob.isNotEmpty)
                _infoRow(
                  Icons.wc_rounded,
                  _blue,
                  [gender, dob].where((v) => v.isNotEmpty).join(' · '),
                ),
              if (phone.isNotEmpty)
                _infoRow(Icons.phone_outlined, _green, phone),
              if (email.isNotEmpty)
                _infoRow(Icons.email_outlined, _red, email),
              if (fullAddress.isNotEmpty)
                _infoRow(Icons.location_on_outlined, _amber, fullAddress),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Host Information',
          child: Column(
            children: [
              _labelValue('Host Type',
                  s['hosterRole']?.toString() ?? 'Individual Owner'),
              const Divider(height: 1, color: _border),
              _labelValue('Status',
                  s['hosterVerified'] == true ? 'Active' : 'Pending Review'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _statsRow(),
        const SizedBox(height: 16),
        _performanceCard(),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // 2. IDENTITY & COMPLIANCE
  // ────────────────────────────────────────────────────────────
  Widget _identityBody() {
    // Determine each doc status from verif fields
    String aadhaarStatus;
    bool aadhaarVerified = s['aadhaarVerified'] == true || s['identityVerified'] == true;
    if (aadhaarVerified) {
      aadhaarStatus = 'Verified';
    } else if (s['aadhaarUrl'] != null) {
      aadhaarStatus = 'In Review';
    } else {
      aadhaarStatus = 'Not Uploaded';
    }

    bool panVerified = s['panVerified'] == true;
    String panStatus;
    if (panVerified) {
      panStatus = 'Verified';
    } else if (s['panUrl'] != null) {
      panStatus = 'In Review';
    } else {
      panStatus = 'Not Uploaded';
    }

    // Business & Property proof — surfaced from stats map
    final businessVerified = s['businessProofVerified'] == true;
    final businessUploaded = s['businessProofUrl'] != null;
    final businessStatus = businessVerified
        ? 'Verified'
        : businessUploaded
            ? 'In Review'
            : 'Not Uploaded';

    final propVerified = s['propertyProofVerified'] == true;
    final propUploaded = s['propertyProofUrl'] != null;
    final propStatus = propVerified
        ? 'Verified'
        : propUploaded
            ? 'In Review'
            : 'Not Uploaded';

    return Column(
      children: [
        _sectionCard(
          title: 'Identity & Compliance',
          trailing: TextButton(
            onPressed: () {},
            child: const Text('View All',
                style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
          ),
          child: Column(
            children: [
              _kycRow(
                Icons.credit_card_rounded,
                const Color(0xFF0EA5E9),
                'Aadhaar Card',
                aadhaarStatus,
                aadhaarVerified,
                subtitle: s['aadhaarNumber'] != null ? _maskId(s['aadhaarNumber'].toString()) : null,
              ),
              const Divider(height: 1, color: _border),
              _kycRow(
                Icons.article_outlined,
                const Color(0xFF8B5CF6),
                'PAN Card',
                panStatus,
                panVerified,
                subtitle: s['panNumber'] != null ? _maskId(s['panNumber'].toString()) : null,
              ),
              const Divider(height: 1, color: _border),
              _kycRow(
                Icons.business_center_outlined,
                const Color(0xFFF59E0B),
                'Business Proof',
                businessStatus,
                businessVerified,
                isReview: businessUploaded && !businessVerified,
              ),
              const Divider(height: 1, color: _border),
              _kycRow(
                Icons.home_work_outlined,
                const Color(0xFF3B82F6),
                'Property Ownership',
                propStatus,
                propVerified,
                isReview: propUploaded && !propVerified,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _navCard(
          Icons.folder_outlined,
          const Color(0xFF3B82F6),
          'Property Documents',
          '${s['totalProperties'] ?? 0} documents',
          () {},
        ),
        const SizedBox(height: 16),
        _uploadInfoCard(),
      ],
    );
  }

  Widget _kycRow(
    IconData icon,
    Color iconColor,
    String title,
    String status,
    bool isVerified, {
    bool isReview = false,
    String? subtitle,
  }) {
    Color statusColor;
    Color statusBg;
    if (isVerified) {
      statusColor = _verified;
      statusBg = _greenLight;
    } else if (isReview) {
      statusColor = _amber;
      statusBg = const Color(0xFFFFF7ED);
    } else {
      statusColor = _muted;
      statusBg = const Color(0xFFF8FAFC);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _text)),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: _sub)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskId(String id) {
    if (id.length <= 4) return id;
    return '${'X' * (id.length - 4)}${id.substring(id.length - 4)}';
  }

  Widget _uploadInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upload clear, readable documents to speed up verification. Documents are encrypted and stored securely.',
              style: TextStyle(fontSize: 12, color: _blue, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // 3. BUSINESS INFORMATION
  // ────────────────────────────────────────────────────────────
  Widget _businessBody() {
    final role = s['hosterRole']?.toString() ?? 'Individual Owner';
    final experience = s['experience']?.toString() ?? '3-5 Years';
    return Column(
      children: [
        _sectionCard(
          title: 'Host Information',
          child: Column(
            children: [
              _labelValue('Host Type', role),
              const Divider(height: 1, color: _border),
              _labelValue('Experience', experience),
              const Divider(height: 1, color: _border),
              _labelValue('Account Status',
                  s['hosterVerified'] == true ? 'Active' : 'Pending'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _statsRow(),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Quick Actions',
          child: Column(
            children: [
              const Divider(height: 1, color: _border),
              _actionRow(Icons.list_alt_rounded, _blue, 'Manage Listings',
                  () {}),
              const Divider(height: 1, color: _border),
              _actionRow(Icons.calendar_today_rounded, _green, 'View Bookings',
                  () {}),
              const Divider(height: 1, color: _border),
              _actionRow(Icons.currency_rupee_rounded, _amber,
                  'Payout History', () {}),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // 4. BANKING & PAYOUTS
  // ────────────────────────────────────────────────────────────
  Widget _bankingBody() {
    final bankName = s['bankName']?.toString() ?? '';
    final accNo = s['bankAccountNo']?.toString() ?? '';
    final ifsc = s['bankIfsc']?.toString() ?? '';
    final maskedAcc = accNo.length > 4
        ? '•••• ${accNo.substring(accNo.length - 4)}'
        : accNo.isEmpty
            ? 'Not added'
            : accNo;
    final bankVerified = s['bankVerified'] == true;
    final upiVerified = s['upiVerified'] == true;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bankName.isNotEmpty ? bankName : 'Bank Account',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        maskedAcc,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              if (ifsc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('IFSC: $ifsc',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _badgePill('Bank Verified', bankVerified),
                  const SizedBox(width: 8),
                  _badgePill('UPI Verified', upiVerified),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Account Details',
          child: Column(
            children: [
              _labelValue('Account Number', maskedAcc),
              const Divider(height: 1, color: _border),
              if (ifsc.isNotEmpty) ...[
                _labelValue('IFSC Code', ifsc),
                const Divider(height: 1, color: _border),
              ],
              _labelValue('Status',
                  bankVerified ? '✓ Verified' : 'Pending verification'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Payout History',
          child: _labelValue(
            'Monthly Revenue',
            '₹${(s['monthlyRevenue'] as num?)?.toStringAsFixed(0) ?? '0'}',
          ),
        ),
      ],
    );
  }

  Widget _badgePill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? _greenLight : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? Icons.verified_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 12,
            color: active ? _verified : Colors.white60,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? _verified : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // 5. PROPERTY SUMMARY
  // ────────────────────────────────────────────────────────────
  Widget _propertySummaryBody() {
    final totalProps = s['totalProperties'] as int? ?? 0;
    final activeListings = s['activeListings'] as int? ?? 0;
    final occupiedRooms = s['activeResidents'] as int? ?? 0;
    final vacantRooms = s['vacantBeds'] as int? ?? 0;
    final revenue =
        '₹${((s['monthlyRevenue'] as num?) ?? 0).toStringAsFixed(0)}';
    final totalBookings = (s['bookingsConfirmed'] as int? ?? 0) +
        (s['pendingCheckins'] as int? ?? 0);
    final completedBookings = s['bookingsConfirmed'] as int? ?? 0;
    final cancellations = 0; // placeholder

    return Column(
      children: [
        _sectionCard(
          title: 'Property Management Summary',
          trailing: TextButton(
            onPressed: () {},
            child: const Text('View All',
                style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
          ),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _summaryCell('Total Properties', '$totalProps',
                  const Color(0xFFEFF6FF), _blue),
              _summaryCell('Active Listings', '$activeListings', _greenLight,
                  _verified),
              _summaryCell('Occupied Rooms', '$occupiedRooms',
                  const Color(0xFFFFF7ED), _amber),
              _summaryCell(
                  'Vacant Rooms', '$vacantRooms', const Color(0xFFFEF2F2), _red),
              _summaryCell('Monthly Revenue', revenue,
                  const Color(0xFFEFF6FF), _blue),
              _summaryCell('Total Bookings', '$totalBookings', _greenLight,
                  _verified),
              _summaryCell('Completed', '$completedBookings',
                  const Color(0xFFF0FDF4), _verified),
              _summaryCell('Cancellations', '$cancellations',
                  const Color(0xFFFEF2F2), _red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCell(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: fg.withValues(alpha: 0.8))),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: fg)),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // 6. PERFORMANCE
  // ────────────────────────────────────────────────────────────
  Widget _performanceBody() {
    return Column(
      children: [
        _performanceCard(),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Key Metrics Explained',
          child: Column(
            children: [
              _metricTip('Response Rate',
                  'Reply to inquiries within 24 hours to keep this high.'),
              const Divider(height: 1, color: _border),
              _metricTip('Acceptance Rate',
                  'Accept more bookings to increase your listing visibility.'),
              const Divider(height: 1, color: _border),
              _metricTip('Cancellation Rate',
                  'Keep cancellations under 5% to maintain a trusted status.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricTip(String title, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: _text)),
          const SizedBox(height: 4),
          Text(tip,
              style: const TextStyle(fontSize: 12, color: _sub, height: 1.4)),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // 7. REVIEWS & RATINGS
  // ────────────────────────────────────────────────────────────
  Widget _reviewsBody() {
    final rating = (s['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = s['reviewCount'] as int? ?? 0;
    final reviewsList = s['reviews'] as List? ?? [];

    double pct5 = 0.0, pct4 = 0.0, pct3 = 0.0, pct2 = 0.0, pct1 = 0.0;
    if (reviewsList.isNotEmpty) {
      int c5 = 0, c4 = 0, c3 = 0, c2 = 0, c1 = 0;
      for (var r in reviewsList) {
        final val = (r['rating'] as num?)?.toDouble() ?? 5.0;
        if (val >= 4.5) {
          c5++;
        } else if (val >= 3.5) {
          c4++;
        } else if (val >= 2.5) {
          c3++;
        } else if (val >= 1.5) {
          c2++;
        } else {
          c1++;
        }
      }
      final len = reviewsList.length;
      pct5 = c5 / len;
      pct4 = c4 / len;
      pct3 = c3 / len;
      pct2 = c2 / len;
      pct1 = c1 / len;
    } else {
      pct5 = 0.8;
      pct4 = 0.15;
      pct3 = 0.05;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _text)),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: i < rating.round()
                            ? Colors.amber
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$reviewCount reviews',
                      style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _ratingBar('5★', pct5, Colors.green),
                    _ratingBar('4★', pct4, Colors.lightGreen),
                    _ratingBar('3★', pct3, _amber),
                    _ratingBar('2★', pct2, Colors.orange),
                    _ratingBar('1★', pct1, _red),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (reviewsList.isEmpty)
          _emptyState(Icons.star_outline_rounded, 'No reviews yet',
              'Reviews from your guests will appear here')
        else
          ...reviewsList.take(5).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _reviewCard(a as Map),
              )),
      ],
    );
  }

  Widget _ratingBar(String label, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: _muted)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: _border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map a) {
    final int ratingValue = ((a['rating'] as num?)?.toInt() ?? 5);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _greenLight,
                child: Text(
                  (a['title']?.toString().isNotEmpty == true)
                      ? a['title'].toString()[0].toUpperCase()
                      : 'G',
                  style: const TextStyle(
                      color: _green, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title'] ?? 'Guest',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(a['time'] ?? '',
                        style:
                            const TextStyle(fontSize: 11, color: _muted)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      size: 12,
                      color:
                          i < ratingValue ? Colors.amber : const Color(0xFFE2E8F0)),
                ),
              ),
            ],
          ),
          if (a['comment']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              a['comment'],
              style: const TextStyle(fontSize: 13, color: _text, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // 8. TRUST SCORE
  // ────────────────────────────────────────────────────────────
  Widget _trustScoreBody() {
    final isVerified = s['hosterVerified'] == true;
    final trustScore = (s['trustScore'] as num?)?.toInt() ?? (isVerified ? 91 : 45);
    final String statusText;
    if (trustScore >= 85) {
      statusText = 'Excellent Host';
    } else if (trustScore >= 50) {
      statusText = 'Good Host';
    } else {
      statusText = 'Building Trust';
    }
    final starValue = (trustScore / 20).round();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: trustScore / 100.0,
                      strokeWidth: 10,
                      backgroundColor: _border,
                      valueColor: const AlwaysStoppedAnimation<Color>(_green),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        trustScore.toString(),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _text),
                      ),
                      const Text('/100',
                          style: TextStyle(fontSize: 12, color: _muted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                statusText,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _text),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      color:
                          i < starValue ? Colors.amber : _border,
                      size: 24),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: _verified, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isVerified
                            ? "You're doing great! Keep providing excellent service."
                            : 'Complete your profile and get verified to increase your score.',
                        style: const TextStyle(
                            fontSize: 12, color: _green, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Trust Factors',
          child: Column(
            children: [
              _trustFactor('Identity Verified',
                  s['identityVerified'] == true),
              const Divider(height: 1, color: _border),
              _trustFactor('Email Verified', s['emailVerified'] == true),
              const Divider(height: 1, color: _border),
              _trustFactor('Phone Verified', s['phoneVerified'] == true),
              const Divider(height: 1, color: _border),
              _trustFactor('Hoster Approved', isVerified),
              const Divider(height: 1, color: _border),
              _trustFactor(
                  'Bank Account Linked', s['hasBankInfo'] == true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trustFactor(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? _verified : _muted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 14, color: _text))),
          if (!done)
            TextButton(
              onPressed: () {},
              style:
                  TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Complete',
                  style: TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // 9. PREFERENCES
  // ────────────────────────────────────────────────────────────
  Widget _preferencesBody() {
    final bookingType = s['prefBookingType']?.toString() ?? '';
    final tenants = s['prefTenants'];
    final gender = s['prefGender']?.toString() ?? '';
    final duration = s['prefDuration']?.toString() ?? '';

    String tenantsStr = '';
    if (tenants is List && tenants.isNotEmpty) {
      tenantsStr = tenants.join(', ');
    }

    return Column(
      children: [
        _sectionCard(
          title: 'Host Preferences',
          child: Column(
            children: [
              _labelValue('Booking Type',
                  bookingType.isNotEmpty ? bookingType : 'Approval Required'),
              const Divider(height: 1, color: _border),
              _labelValue('Preferred Tenants',
                  tenantsStr.isNotEmpty ? tenantsStr : 'Students, Professionals'),
              const Divider(height: 1, color: _border),
              _labelValue('Preferred Gender',
                  gender.isNotEmpty ? gender : 'Any'),
              const Divider(height: 1, color: _border),
              _labelValue('Preferred Duration',
                  duration.isNotEmpty ? duration : 'Long Term, Short Term'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _amber, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your preferences help match you with the right tenants. Tap Edit above to update.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // 10. EMERGENCY CONTACT
  // ────────────────────────────────────────────────────────────
  Widget _emergencyBody() {
    final name = s['emergencyContactName']?.toString() ?? '';
    final phone = s['emergencyContactPhone']?.toString() ?? '';

    return Column(
      children: [
        if (name.isEmpty && phone.isEmpty)
          _emptyState(
            Icons.contact_emergency_outlined,
            'No Emergency Contact',
            'Add an emergency contact for account security',
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: _amber, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Emergency Contact',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _text),
                      ),
                      if (phone.isNotEmpty)
                        Text(phone,
                            style: const TextStyle(
                                fontSize: 14, color: _sub)),
                    ],
                  ),
                ),
                if (phone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: _green),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Phone copied: $phone')),
                      );
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _sectionCard(
          title: 'Quick Actions',
          child: Column(
            children: [
              _actionRow(Icons.contact_phone_outlined, _blue, 'Select from Contacts', _pickEmergencyContact),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Why add an emergency contact?',
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'An emergency contact helps us reach someone on your behalf in case of urgent situations or account recovery.',
              style: TextStyle(fontSize: 13, color: _sub, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // 11. SECURITY CENTER
  // ────────────────────────────────────────────────────────────
  Widget _securityBody() {
    return Column(
      children: [
        _sectionCard(
          title: 'Security Settings',
          child: Column(
            children: [
              _securityRow(
                  Icons.lock_outline_rounded, _green, 'Change Password', () {}),
              const Divider(height: 1, color: _border),
              _securityRow(Icons.phonelink_lock_rounded, _blue,
                  'Two-Factor Authentication', () {}),
              const Divider(height: 1, color: _border),
              _securityRow(
                  Icons.devices_rounded, _sub, 'Active Devices', () {}),
              const Divider(height: 1, color: _border),
              _securityRow(Icons.history_rounded, _amber, 'Login History', () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _greenLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.security_rounded, color: _green, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your account is protected. We recommend enabling 2FA for extra security.',
                  style: TextStyle(
                      fontSize: 12, color: _green, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _securityRow(
      IconData icon, Color color, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _text))),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // 12. NOTIFICATION SETTINGS
  // ────────────────────────────────────────────────────────────
  Widget _notificationsBody() {
    return _sectionCard(
      title: 'Notification Preferences',
      child: Column(
        children: [
          _notifToggle('New Booking Requests', true),
          const Divider(height: 1, color: _border),
          _notifToggle('Payment Received', true),
          const Divider(height: 1, color: _border),
          _notifToggle('Check-in Reminders', true),
          const Divider(height: 1, color: _border),
          _notifToggle('Review Received', false),
          const Divider(height: 1, color: _border),
          _notifToggle('Promotional Offers', false),
          const Divider(height: 1, color: _border),
          _notifToggle('System Alerts', true),
        ],
      ),
    );
  }

  Widget _notifToggle(String label, bool initial) {
    return StatefulBuilder(builder: (_, setState) {
      var value = initial;
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: (v) => setState(() => value = v),
        activeThumbColor: _green,
      );
    });
  }

  // ────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ────────────────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _text)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 14, color: _text))),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _sub))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _text)),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCell(
              'Total Properties', '${s['totalProperties'] ?? 0}', _blue),
          _vLine(),
          _statCell('Total Rooms', '${s['totalRooms'] ?? 0}', _red),
          _vLine(),
          _statCell('Active Listings', '${s['activeListings'] ?? 0}', _green),
        ],
      ),
    );
  }

  Widget _statCell(String label, String val, Color color) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: _muted)),
      ],
    );
  }

  Widget _vLine() => Container(
        width: 1,
        height: 36,
        color: _border,
      );

  Widget _performanceCard() {
    return _sectionCard(
      title: 'Performance Overview',
      trailing: TextButton(
        onPressed: () {},
        child: const Text('View All',
            style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
      ),
      child: Column(
        children: [
          _perfRow(Icons.reply_rounded, _green, 'Response Rate', '98%'),
          const Divider(height: 1, color: _border),
          _perfRow(Icons.timer_outlined, _blue, 'Avg. Response Time', '12 mins'),
          const Divider(height: 1, color: _border),
          _perfRow(
              Icons.check_circle_outline_rounded, _verified, 'Acceptance Rate', '95%'),
          const Divider(height: 1, color: _border),
          _perfRow(Icons.cancel_outlined, _red, 'Cancellation Rate', '3%'),
        ],
      ),
    );
  }

  Widget _perfRow(
      IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _sub))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _text)),
        ],
      ),
    );
  }

  Widget _navCard(
      IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _text)),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(
      IconData icon, Color color, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _text))),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: _border),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _text)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: _muted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Convenience factory to build the detail screen from the profile ──────────
extension HosterProfileDetailRoute on HosterProfileSection {
  String get label {
    switch (this) {
      case HosterProfileSection.basicInfo:
        return 'Basic Information';
      case HosterProfileSection.identity:
        return 'Identity & Compliance';
      case HosterProfileSection.business:
        return 'Business Information';
      case HosterProfileSection.banking:
        return 'Banking & Payouts';
      case HosterProfileSection.propertySummary:
        return 'Property Summary';
      case HosterProfileSection.performance:
        return 'Performance';
      case HosterProfileSection.reviews:
        return 'Reviews & Ratings';
      case HosterProfileSection.trustScore:
        return 'Trust Score';
      case HosterProfileSection.preferences:
        return 'Preferences';
      case HosterProfileSection.emergency:
        return 'Emergency Contact';
      case HosterProfileSection.security:
        return 'Security Center';
      case HosterProfileSection.notifications:
        return 'Notification Settings';
    }
  }
}

// ── Quick Actions stand-alone screen ─────────────────────────────────────────
class HosterQuickActionsScreen extends StatelessWidget {
  final Map<String, dynamic> stats;
  const HosterQuickActionsScreen({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        title: const Text('Quick Actions',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _actionCard(
            context,
            Icons.add_home_work_rounded,
            const Color(0xFF6366F1),
            'Add New Property',
            'List a new property and start earning',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListPropertyScreen()),
            ),
          ),
          _actionCard(
            context,
            Icons.home_work_outlined,
            const Color(0xFF3B82F6),
            'Manage Listings',
            'View and update your properties',
            () {},
          ),
          _actionCard(
            context,
            Icons.calendar_today_rounded,
            const Color(0xFF10B981),
            'View Bookings',
            'See all your booking requests',
            () {},
          ),
          _actionCard(
            context,
            Icons.currency_rupee_rounded,
            const Color(0xFFF59E0B),
            'Payout History',
            'Track your earnings and payouts',
            () {},
          ),
          _actionCard(
            context,
            Icons.dashboard_rounded,
            const Color(0xFF1B4332),
            'Host Dashboard',
            'Overview of your hosting activity',
            () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
