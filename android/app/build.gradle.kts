import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (see README "Release signing"). The upload keystore and its
// passwords live ONLY on the owner's machine in android/key.properties
// (git-ignored; template: android/key.properties.example). If the file is
// missing, release builds fall back to the debug key so CI/agent builds keep
// working — such APKs are for testing only, never for Play.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
    for (k in listOf("storeFile", "storePassword", "keyAlias", "keyPassword")) {
        if (keystoreProperties.getProperty(k).isNullOrBlank()) {
            throw GradleException("android/key.properties is missing '$k' (see key.properties.example)")
        }
    }
} else {
    logger.warn(
        "WARNING: android/key.properties not found — release build is signed with the DEBUG key " +
            "(test builds only, not for Google Play).",
    )
}

android {
    namespace = "com.offerforge.gizlialan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.offerforge.gizlialan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 9+: BiometricPrompt + modern Keystore; avoids AppCompat theme
        // issues of FragmentActivity on Android 8 and below.
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Two distributions (issue #11, owner decision v0.5.0 #52):
    //  - full: everything incl. the Second phone (work profile) + Play
    //    Billing. THIS is the Google Play upload (AAB) since v0.5.0.
    //  - play: fallback "lite" build — vault + calculator only, NO Second
    //    phone: no device-admin receiver, no work-profile code (src/full is
    //    not compiled in). Also has Play Billing.
    // Both use applicationId com.offerforge.gizlialan (the Play Console app),
    // so they replace each other on a device.
    // Build with `flutter build apk --flavor play|full` (Dart reads appFlavor).
    flavorDimensions += "distribution"
    productFlavors {
        create("play") {
            dimension = "distribution"
        }
        create("full") {
            dimension = "distribution"
        }
    }

    signingConfigs {
        // CI (android-test-build.yml) points this at the restored shared debug
        // keystore so test APKs keep the same signer as earlier *-test builds.
        System.getenv("GIZLI_DEBUG_KEYSTORE")?.takeIf { it.isNotBlank() }?.let { path ->
            getByName("debug") {
                storeFile = file(path)
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
        if (hasReleaseKeystore) {
            create("release") {
                // storeFile is resolved relative to the android/ directory.
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Flutter enables R8 for release; add the TikTok SDK keep rules.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // JVM unit tests only (android/app/src/testFull: Second phone HidePolicy,
    // issue #30). Not packaged into any APK.
    testImplementation("junit:junit:4.13.2")

    // TikTok Business (App Events) SDK — install/launch attribution + Pro
    // Purchase event (lib/services/analytics.dart → TikTokChannel.kt).
    // Lifecycle + Install Referrer as required by the official integration
    // guide. Initialised from Dart only when the App Secret was injected.
    implementation("com.github.tiktok:tiktok-business-android-sdk:1.7.1")
    implementation("androidx.lifecycle:lifecycle-process:2.8.7")
    implementation("androidx.lifecycle:lifecycle-common-java8:2.8.7")
    implementation("com.android.installreferrer:installreferrer:2.2")

    // Joi (0.6.2): Gemini Nano on-device via ML Kit GenAI Prompt API (AICore).
    // Inference runs on the device only (JoiChannel.kt).
    implementation("com.google.mlkit:genai-prompt:1.0.0-beta4")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")

    // Joi online fallback (0.6.2): Firebase AI Logic (Gemini Developer API)
    // for GENERAL questions only, opt-in with consent; never note content.
    // Firebase is initialised at runtime from --dart-define values (no
    // google-services.json / gms plugin); without them it is never touched.
    // App Check (Play Integrity) is installed on that app for abuse protection.
    implementation(platform("com.google.firebase:firebase-bom:35.1.0"))
    implementation("com.google.firebase:firebase-ai")
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
    // 0.6.5: Google Analytics for Firebase (active users, joi_question,
    // pro_purchase). Default app initialised at runtime (FirebaseAnalyticsChannel.kt).
    implementation("com.google.firebase:firebase-analytics")
    // Debug provider: used only when built with JOI_APPCHECK_DEBUG_TOKEN
    // (sideloaded test APKs); the token must be registered in the console.
    implementation("com.google.firebase:firebase-appcheck-debug")

    // Google Play In-App Updates (flexible), 0.6.2. No-op on sideloaded APKs.
    implementation("com.google.android.play:app-update:2.1.0")
}
