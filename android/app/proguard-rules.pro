# Flutter ProGuard / R8 rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.kashmir.zoology.zoology_app.** { *; }
-dontwarn io.flutter.embedding.**
