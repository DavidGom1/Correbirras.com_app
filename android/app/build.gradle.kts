import java.io.FileInputStream
import java.io.IOException
import java.util.Properties
import com.android.build.api.dsl.ApplicationDefaultConfig
import org.gradle.api.GradleException
import org.gradle.api.JavaVersion

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use {
        localProperties.load(it)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
val flutterVersionName = localProperties.getProperty("flutter.versionName")

android {
    namespace = "com.correbirras.agenda"
    compileSdk = 35

        compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

       kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.correbirras.agenda"
        minSdk = 26
        targetSdk = 35
        versionCode = flutterVersionCode.toString().toInt()
        versionName = flutterVersionName
    }

    signingConfigs {
        create("release") {
            val keystoreFile = localProperties.getProperty("keystore.file")
            val keystorePassword = localProperties.getProperty("keystore.password")
            val keyAliasValue = localProperties.getProperty("key.alias")
            val keyPasswordValue = localProperties.getProperty("key.password")
            
            if (keystoreFile != null && keystorePassword != null && keyAliasValue != null && keyPasswordValue != null) {
                storeFile = file(keystoreFile)
                storePassword = keystorePassword
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            }
        }
    }

    buildTypes {
        release {
            val releaseSigningConfig = signingConfigs.getByName("release")
            if (releaseSigningConfig.storeFile != null) {
                signingConfig = releaseSigningConfig
            }
            isMinifyEnabled = true // <-- Cambiado a true
            isShrinkResources = true // <-- Cambiado a true
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.6.0")
}

flutter {
    source = "../.."
}
