pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// Remove any `--release` compiler args from JavaCompile tasks across projects.
// This is necessary because some plugins may inject the `--release` flag which
// is incompatible with the Android Gradle plugin. We perform this in
// `projectsEvaluated` so it happens early during configuration.
gradle.projectsEvaluated {
    rootProject.allprojects.forEach { p ->
        p.tasks.withType(org.gradle.api.tasks.compile.JavaCompile::class.java).configureEach {
            val filtered = options.compilerArgs.filter { it != "--release" }
            options.compilerArgs.clear()
            options.compilerArgs.addAll(filtered)
        }
    }
}
