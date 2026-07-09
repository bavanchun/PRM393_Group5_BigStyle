import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bigstyle.bigstyle_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bigstyle.bigstyle_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Native Android Maps SDK key — package+SHA-1 restricted, distinct
        // from the dotenv GOOGLE_MAPS_API_KEY used for the Directions REST
        // call (that key is bundled into the APK as a Flutter asset and
        // must stay API-restricted + quota-capped, not package-restricted;
        // see FE/.env.example). Read from android/local.properties (git-
        // ignored, machine-local) or the environment, never committed.
        val mapsApiKey: String = run {
            val props = Properties()
            val localProps = rootProject.file("local.properties")
            if (localProps.exists()) {
                localProps.inputStream().use { props.load(it) }
            }
            props.getProperty("GOOGLE_MAPS_API_KEY")
                ?: System.getenv("GOOGLE_MAPS_API_KEY")
                ?: ""
        }
        if (mapsApiKey.isEmpty()) {
            logger.warn(
                "GOOGLE_MAPS_API_KEY not set in android/local.properties or " +
                    "env — native map will not render on this build."
            )
        }
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
    }

    // ĐOẠN CẤU HÌNH KEYSTORE CHUNG CHO CẢ TEAM NẰM Ở ĐÂY
    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
