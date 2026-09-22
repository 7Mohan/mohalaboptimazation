# -----------------------------------------------------------------------------
# Moha Lab Optimization — R8 & ProGuard Hardening Rules
# -----------------------------------------------------------------------------

# Flutter Engine & Embeddings
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods and entry points
-keepclasseswithmembers class * {
    native <methods>;
}

-keepclassmembers class * extends java.lang.Enum {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Shizuku Binder IPC
-dontwarn rikka.shizuku.**
-keep class rikka.shizuku.** { *; }
-keep interface rikka.shizuku.** { *; }

# Google Mobile Ads (AdMob) SDK
-keep class com.google.android.gms.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Strip all android.util.Log calls in release builds (Safe Logging)
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Preserve line numbers and source file attributes for stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter Deferred Components / Play Store split install (suppress optional Play Core warnings)
-dontwarn com.google.android.play.core.**

