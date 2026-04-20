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
