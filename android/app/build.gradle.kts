plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter Gradle Plugin configuration access
val flutterVersionCode = project.properties["flutter.versionCode"] ?: "1"
val flutterVersionName = project.properties["flutter.versionName"] ?: "1.0.0"

android {
    namespace = "com.example.chinese_food_app"
    compileSdk = 34
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.chinese_food_app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutterVersionCode.toString().toInt()
        versionName = flutterVersionName.toString()
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
