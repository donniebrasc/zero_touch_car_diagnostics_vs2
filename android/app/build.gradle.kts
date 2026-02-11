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
        versionCode = 5
        versionName = "ZTCDv1.32.12BETA"
    }

    signingConfigs {
        create("release") {
            // If a release.keystore is present we will use it. Otherwise the build
            // will produce an unsigned APK (app-release-unsigned.apk).
            val ksFile = file("${project.projectDir}/release.keystore")
            if (ksFile.exists()) {
                storeFile = ksFile
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "changeit"
                keyAlias = System.getenv("KEY_ALIAS") ?: "key"
                keyPassword = System.getenv("KEY_PASSWORD") ?: "changeit"
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            val ksFile = file("${project.projectDir}/release.keystore")
            if (ksFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // No release keystore found — the resulting APK will be unsigned.
            }
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

// A small Gradle task to rename the produced APK to the requested filename
// after assembleRelease runs. This copies the signed or unsigned APK to
// ZTCDv1.32.12BETA.apk for easier artifact uploading.

tasks.register("renameReleaseApk") {
    dependsOn("assembleRelease")
    doLast {
        val apkDir = file("${project.buildDir}/outputs/apk/release")
        val signed = apkDir.resolve("app-release.apk")
        val unsigned = apkDir.resolve("app-release-unsigned.apk")
        val out = apkDir.resolve("ZTCDv1.32.12BETA.apk")
        if (signed.exists()) {
            signed.copyTo(out, overwrite = true)
            println("Copied signed APK to ${out}")
        } else if (unsigned.exists()) {
            unsigned.copyTo(out, overwrite = true)
            println("Copied unsigned APK to ${out}")
        } else {
            println("No release APK found to rename in ${apkDir}")
        }
    }
}