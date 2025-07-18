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
    namespace = "com.correbirras.myapp"
    compileSdkVersion(35)

        compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

       kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.correbirras.myapp"
        minSdkVersion(26)
        targetSdkVersion(35)
        versionCode = flutterVersionCode.toString().toInt()
        versionName = flutterVersionName
    }

    signingConfigs {
        create("release") {
            storeFile = file(localProperties.getProperty("keystore.file") ?: "keystore.jks")
            storePassword = localProperties.getProperty("keystore.password")
            keyAlias = localProperties.getProperty("key.alias")
            keyPassword = localProperties.getProperty("key.password")
            if (storePassword == null || keyAlias == null || keyPassword == null) {
                throw GradleException("Missing signing config values in local.properties")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.6.0")
}

flutter {
    source = "../.."
}
