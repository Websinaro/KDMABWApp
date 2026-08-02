# WeBAlert ProGuard rules

# Keep Flutter Play Store split application classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play core (deferred components) - avoids missing class warnings on some Flutter versions
-dontwarn com.google.android.play.core.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Secure storage (Android Keystore backed)
-keep class com.it_nomads.fluttersecurestorage.** { *; }
