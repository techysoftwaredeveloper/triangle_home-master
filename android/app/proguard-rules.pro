# Razorpay core
-keep class com.razorpay.** { *; }
-keep interface com.razorpay.** { *; }

# Suppress missing class errors for proguard annotations
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Keep class structure to avoid reflection issues
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Optional: general Android support
-dontwarn org.apache.**
-dontwarn android.net.http.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Pay API references (used internally by Razorpay)
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# Firebase App Check + Play Integrity
-keep class com.google.firebase.appcheck.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.android.play.core.integrity.**

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Firebase Storage
-keep class com.google.firebase.storage.** { *; }

# Isar database
-keep class io.isar.** { *; }
-dontwarn io.isar.**

# Google Sign In
-keep class io.flutter.plugins.googlesignin.** { *; }
-dontwarn io.flutter.plugins.googlesignin.**
