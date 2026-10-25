# Cikoko v2509: conservative R8 rules for Flutter plugin registration.
# Android Gradle plugin and Flutter dependencies include consumer rules for
# AndroidX, Firebase, Google Play services, WebView and serialization.
# Avoid global -keep class ** { *; } as it disables useful obfuscation.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class com.KelurahanCikoko.malik.MainActivity { *; }
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod
