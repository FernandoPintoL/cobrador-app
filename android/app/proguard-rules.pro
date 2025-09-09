# Keep SLF4J binding classes to avoid R8 missing class errors
-keep class org.slf4j.** { *; }
-dontwarn org.slf4j.**

# Some libraries reference optional LoggerFactory binders; keep them
-keep class org.slf4j.impl.** { *; }
-dontwarn org.slf4j.impl.**

# Keep classes used by image picker / activity result APIs (safety)
-keep class androidx.activity.result.** { *; }
-dontwarn androidx.activity.result.**
