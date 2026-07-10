allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// file_picker 11 بيشوف AGP 9 فبيفترض إن Kotlin مدمج وبيبطل يطبّقه بنفسه،
// لكن قالب Flutter معطّل الـ built-in Kotlin — فنطبّق KGP على الموديول يدويًا.
subprojects {
    if (name == "file_picker") {
        plugins.withId("com.android.library") {
            apply(plugin = "org.jetbrains.kotlin.android")
        }
    }
}

// توحيد jvmTarget مع الـ Java target بتاع كل موديول — Gradle الحديث يرفض
// التضارب. flutter_timezone بيبني Java على 11، و file_picker على 17.
subprojects {
    val kotlinJvmTargetFix = mapOf(
        "flutter_timezone" to org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11,
        "file_picker" to org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
    )
    kotlinJvmTargetFix[name]?.let { target ->
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(target)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
