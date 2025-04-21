plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.callidoraglobalmedia.slangthatthang"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.callidoraglobalmedia.slangthatthang"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // if your path has spaces, use raw string with triple quotes
//            storeFile  = file("""C:\\Users\\ahmed\\OneDrive\\Desktop\\Slang that Thang\\Upload Key\\UploadKey.jks""")
            storeFile = file("upload-keystore.jks")
            storePassword = "slangthatthang"
            keyAlias      = "slangthatthang"
            keyPassword   = "slangthatthang"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }

//    buildTypes {
//        release {
//            // enable code shrinking if you want (optional)
//            isMinifyEnabled = false
//            // point to your new signing config:
//            signingConfig = signingConfigs.getByName("release")
//        }
//        // you can also explicitly sign debug if you like:
//        debug {
//            // signingConfig = signingConfigs.getByName("release")
//        }
//    }
}

flutter {
    source = "../.."
}
