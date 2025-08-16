# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep our models
-keep class com.taskflow.taskflow_flutter.models.** { *; }

# General Android rules
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn android.arch.**
-dontwarn androidx.**