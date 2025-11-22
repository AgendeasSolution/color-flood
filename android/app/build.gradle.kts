plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.fgtp.color_flood"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fgtp.color_flood"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable ProGuard/R8 code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

repositories {
    google()
    mavenCentral()
    // IronSource Maven repository
    maven { url = uri("https://android-sdk.is.com/") }
    // AppLovin Maven repository
    maven { url = uri("https://artifacts.applovin.com/android") }
}

dependencies {
    implementation("com.facebook.android:facebook-android-sdk:[8,9)")
    
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    
    // When using the BoM, don't specify versions in Firebase dependencies
    // Add the dependencies for Firebase products you want to use
    implementation("com.google.firebase:firebase-analytics")
    
    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
    
    // Unity Ads + Google mediation adapter
    implementation("com.unity3d.ads:unity-ads:4.9.1")
    implementation("com.google.ads.mediation:unity:4.9.1.0")
    
    // ironSource + Google mediation adapter
    implementation("com.ironsource.sdk:mediationsdk:8.4.0")
    implementation("com.google.ads.mediation:ironsource:8.4.0.0")
    
    // AppLovin (MAX) + Google mediation adapter
    implementation("com.applovin:applovin-sdk:13.0.0")
    implementation("com.google.ads.mediation:applovin:13.0.0.0")
    
    // Meta / Facebook Audience Network + Google mediation adapter
    implementation("com.facebook.android:audience-network-sdk:6.16.0")
    implementation("com.google.ads.mediation:facebook:6.16.0.0")
}
