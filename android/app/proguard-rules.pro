# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.android.gms.measurement.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.ads.**

# Keep Google Mobile Ads mediation adapters
-keep class com.google.ads.mediation.** { *; }
-keepattributes *Annotation*
-keep class * extends com.google.ads.mediation.MediationAdapter
-keep class * extends com.google.ads.mediation.MediationServerParameters

# Unity Ads
-keep class com.unity3d.** { *; }
-dontwarn com.unity3d.**

# ironSource
-keep class com.ironsource.** { *; }
-dontwarn com.ironsource.**
-keepattributes *Annotation*
-keepattributes Signature
-keep class com.ironsource.mediationsdk.** { *; }

# AppLovin (MAX)
-keep class com.applovin.** { *; }
-dontwarn com.applovin.**
-keepattributes *Annotation*
-keepattributes Signature

# Facebook SDK
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**
-keepattributes *Annotation*
-keepattributes Signature

# Facebook Audience Network
-keep class com.facebook.ads.** { *; }
-dontwarn com.facebook.ads.**

# OneSignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Keep custom application class
-keep public class * extends android.app.Application

# Keep Activity classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Fragment
-keep public class * extends androidx.fragment.app.Fragment

# Keep View constructors
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep native method names
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep JavaScript interface for WebView
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep reflection-based classes
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
    @androidx.annotation.Keep <fields>;
    @androidx.annotation.Keep <init>(...);
}

# OkHttp (used by various SDKs)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Gson (used by various SDKs)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Retrofit (if used)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature, Exceptions
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# Jackson (if used)
-dontwarn com.fasterxml.jackson.databind.**
-keep class com.fasterxml.jackson.databind.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.** {
    volatile <fields>;
}

# Keep all model classes (adjust package name as needed)
-keep class com.fgtp.color_flood.** { *; }

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Additional R8 fixes
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep all Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.plugins.** { *; }

# Keep all package classes that might be accessed via reflection
-keep class androidx.** { *; }
-dontwarn androidx.**

# Keep WebView classes
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebChromeClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# Keep URL launcher classes
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep connectivity classes
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Keep shared preferences classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep package info classes
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# Keep audio players classes
-keep class xyz.luan.audioplayers.** { *; }

# Keep Google Fonts classes
-keep class io.flutter.plugins.googlefonts.** { *; }

# Keep HTTP classes
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep Firebase Messaging (if used)
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Keep all model classes with @Keep annotation
-keep @androidx.annotation.Keep class * { *; }

# Keep classes that are referenced in AndroidManifest.xml
-keep class * extends android.app.Activity
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider

# Additional Kotlin rules
-keepclassmembers class kotlin.** {
    public <methods>;
}
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class **$WhenMappings$When {
    <methods>;
}

# Keep data classes
-keepclassmembers class * {
    @kotlin.jvm.JvmField <fields>;
}

# Keep companion objects
-keepclassmembers class * {
    public static ** Companion;
}

# Keep object instances
-keepclassmembers class * {
    public static ** INSTANCE;
}

# Suppress warnings for missing classes
-dontwarn kotlinx.coroutines.**
-dontwarn kotlin.reflect.**
-dontwarn kotlin.Unit
-dontwarn kotlin.collections.**
-dontwarn kotlin.jvm.internal.**
-dontwarn kotlin.coroutines.**

# Google Play Core (optional dependency for deferred components)
# These rules are generated automatically by R8 to suppress warnings about missing classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Flutter deferred components (Play Store split install)
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# R8 full mode compatibility
-allowaccessmodification
-repackageclasses ''

