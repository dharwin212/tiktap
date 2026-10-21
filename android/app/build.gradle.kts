import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.tiktap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.tiktap"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = System.getenv("KEY_ALIAS")
                ?: keystoreProperties.getProperty("keyAlias")
                ?: "tiktap"
            val keyPasswordVal = System.getenv("KEY_PASSWORD")
                ?: keystoreProperties.getProperty("keyPassword")
                ?: "tiktapsecret"
            val storePasswordVal = System.getenv("STORE_PASSWORD")
                ?: keystoreProperties.getProperty("storePassword")
                ?: "tiktapsecret"
            val storeFileProp = System.getenv("STORE_FILE")
                ?: keystoreProperties.getProperty("storeFile")
                ?: "tiktap-release.jks"

            keyAlias = keyAliasVal
            keyPassword = keyPasswordVal
            storePassword = storePasswordVal
            storeFile = file(storeFileProp)
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            val releaseFile = releaseSigning.storeFile
            if (releaseFile != null && releaseFile.exists()) {
                signingConfig = releaseSigning
            } else {
                signingConfig = signingConfigs.getByName("debug")
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
