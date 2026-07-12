plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hhub.my_assistant"
    // receive_sharing_intent 1.9 بيتطلب compileSdk 37 (المنصة اتنسخت
    // لـ android-37 يدويًا لأن الـ SDK بينزلها باسم android-37.0).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hhub.my_assistant"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // حزمة health (Health Connect) محتاجة 26 على الأقل.
        minSdk = maxOf(26, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // lintVital بيقفل ملفات الـ cache على ويندوز (تعارض مع مضاد الفيروسات) —
    // بنوقفه لأنه تحليل فقط ومابيأثرش على ناتج البناء.
    lint {
        checkReleaseBuilds = false
        abortOnError = false
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // home_widget → glance 1.0.0 بيسحب work 2.7.1 و Room 2.2.5 القدام جدًا،
    // ودول بيكسروا إقلاع التطبيق على أندرويد الحديث في نسخ الـ release
    // (FATAL: Failed to create an instance of WorkDatabase). نفرض إصدارات حديثة.
    implementation("androidx.work:work-runtime:2.9.1")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    implementation("androidx.room:room-runtime:2.6.1")
}
