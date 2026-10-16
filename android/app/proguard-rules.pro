# Flutter Wrapper Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep App Package & Activities (Prevents ClassNotFoundException on MainActivity)
-keep class com.example.orbit.** { *; }
-keep class app.orbit.training.** { *; }
-keep public class * extends io.flutter.embedding.android.FlutterActivity
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

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
