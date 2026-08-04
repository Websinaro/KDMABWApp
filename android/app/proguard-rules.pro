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

# Firebase Cloud Messaging - required or SOS push notifications silently
# fail to deliver/display in release builds only, since R8 strips classes
# only referenced via plugin registration, not direct Dart calls.
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# flutter_local_notifications - required for the SOS full-screen alert +
# custom sound to actually render.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Our own MainActivity's MethodChannel (DND bypass bridge)
-keep class com.websinaro.webalert.MainActivity { *; }
