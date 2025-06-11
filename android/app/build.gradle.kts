plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.crave_food"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.crave_food"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        
        multiDexEnabled = true
    }

    buildTypes {
        debug {
            isDebuggable = true
            // Keep it simple for debug builds
            isMinifyEnabled = false
            isShrinkResources = false
            versionNameSuffix = "-debug"
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Enable optimization for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}