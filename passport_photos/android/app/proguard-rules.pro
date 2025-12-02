# Keep OkHttp & Okio (used by uCrop)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Keep uCrop classes
-keep class com.yalantis.ucrop.** { *; }

# Ignore warnings
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.yalantis.ucrop.**
