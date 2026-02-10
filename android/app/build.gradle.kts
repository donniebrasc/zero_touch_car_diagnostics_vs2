plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

subprojects {
    afterEvaluate {
        if (pluginManager.hasPlugin("com.android.library")) {
            extensions.getByType<com.android.build.gradle.LibraryExtension>().apply {
                namespace = namespace ?: "com.example.flutter.plugins"
            }
        }
    }
}

android {
    namespace = "com.example.zero_touch_car_diagnostics"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.zero_touch_car_diagnostics"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Explicitly set versionCode/versionName for this release
        versionCode = 4
        versionName = "ZTCD_v1.32.11.beta"
    }

    signingConfigs {
        create("release") {
            // Keystore file will be provided by CI by decoding KEYSTORE_BASE64
            storeFile = file("${project.projectDir}/release.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "changeit"
            keyAlias = System.getenv("KEY_ALIAS") ?: "key"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "changeit"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // Enable CMake for native C++ code (backend bridge)
    // Temporarily disabled for release build
    // externalNativeBuild {
    //     cmake {
    //         path = file("CMakeLists.txt")
    //         version = "3.18.1"
    //     }
    // }
}

flutter {
    source = "../.."
}
