import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUtils {
  /// Options for fetching critical data that MUST come from the server
  static const GetOptions serverOnly = GetOptions(source: Source.server);

  /// Options for fetching data that can be cached
  static const GetOptions cacheFirst = GetOptions(
    source: Source.serverAndCache,
  );
}
