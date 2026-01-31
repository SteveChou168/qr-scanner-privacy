# Flutter ProGuard Rules
# QR Scanner App - Release Build Configuration

# ============ Flutter Core ============
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ============ Mobile Scanner (Camera/Barcode) ============
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**

# ============ SQLite Database ============
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# ============ Image Processing ============
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# ============ Share Plus ============
-keep class androidx.core.content.FileProvider { *; }

# ============ Location Services ============
-keep class com.google.android.gms.location.** { *; }

# ============ Kotlin ============
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# ============ AndroidX ============
-keep class androidx.** { *; }
-dontwarn androidx.**

# ============ General Android ============
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============ Google Play Core (Deferred Components) ============
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }

# ============ R8 Full Mode ============
-allowaccessmodification
-repackageclasses ''
