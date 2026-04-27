# Keep SLF4J binding classes to avoid R8 missing class errors
-keep class org.slf4j.** { *; }
-dontwarn org.slf4j.**

# Some libraries reference optional LoggerFactory binders; keep them
-keep class org.slf4j.impl.** { *; }
-dontwarn org.slf4j.impl.**

# Keep classes used by image picker / activity result APIs (safety)
-keep class androidx.activity.result.** { *; }
-dontwarn androidx.activity.result.**

# ML Kit optional language modules (not included in this build)
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
