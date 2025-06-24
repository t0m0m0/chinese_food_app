plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter Gradle Plugin configuration access
val flutterVersionCode = project.properties["flutter.versionCode"] ?: "1"
val flutterVersionName = project.properties["flutter.versionName"] ?: "1.0.0"
val flutterCompileSdkVersion = project.properties["flutter.compileSdkVersion"]?.toString()?.toInt() ?: 34
val flutterMinSdkVersion = project.properties["flutter.minSdkVersion"]?.toString()?.toInt() ?: 21
val flutterTargetSdkVersion = project.properties["flutter.targetSdkVersion"]?.toString()?.toInt() ?: 34

android {
    namespace = "com.example.chinese_food_app"
    compileSdk = flutterCompileSdkVersion
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.chinese_food_app"
        minSdk = flutterMinSdkVersion
        targetSdk = flutterTargetSdkVersion
        versionCode = flutterVersionCode.toString().toInt()
        versionName = flutterVersionName.toString()
        
        // Google Maps APIキーを環境変数から取得、なければダミーキーを使用
        val googleMapsApiKey = System.getenv("GOOGLE_MAPS_API_KEY") ?: "AIzaSyDUMMY_KEY_FOR_CI_ENVIRONMENT"
        resValue("string", "google_maps_api_key", googleMapsApiKey)
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
