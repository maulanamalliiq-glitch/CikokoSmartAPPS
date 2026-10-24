import java.util.Properties
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
val signingFile = System.getenv("CIKOKO_KEYSTORE_PATH")
android {
    namespace = "com.KelurahanCikoko.malik"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17; isCoreLibraryDesugaringEnabled = true }
    kotlinOptions { jvmTarget = "17" }
    defaultConfig {
        applicationId = "com.KelurahanCikoko.malik"
        minSdk = 24
        targetSdk = 36
        versionCode = 206
        versionName = "1.0.206"
        multiDexEnabled = true
    }
    signingConfigs {
        create("upload") {
            if (!signingFile.isNullOrBlank()) {
                storeFile = file(signingFile)
                storePassword = System.getenv("CIKOKO_STORE_PASSWORD")
                keyAlias = System.getenv("CIKOKO_KEY_ALIAS") ?: "androidkey"
                keyPassword = System.getenv("CIKOKO_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        getByName("release") {
            if (!signingFile.isNullOrBlank()) signingConfig = signingConfigs.getByName("upload")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
flutter { source = "../.." }
dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5") }
