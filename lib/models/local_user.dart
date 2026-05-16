import 'package:isar/isar.dart';

part 'local_user.g.dart';

@collection
class LocalUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? uid;

  String? name;
  String? email;
  String? phoneNumber;
  String? profilePicture;
  String? role;

  DateTime? lastUpdated;

  LocalUser({
    this.uid,
    this.name,
    this.email,
    this.phoneNumber,
    this.profilePicture,
    this.role,
    this.lastUpdated,
  });
}
