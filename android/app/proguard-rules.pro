# Flutter Wrapper Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Core & Firestore
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# Guava / Protocol Buffers (Firestore internal)
-dontwarn com.google.common.**
-dontwarn com.google.protobuf.**

# Keep models for JSON serialization if needed
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Play Store Split Install / Deferred Components (Flutter Engine optional references)
-dontwarn com.google.android.play.core.**
