// Init script: run early during Gradle init to remove any `--release` compiler args
// which are incompatible with the Android Gradle plugin's bootclasspath setup.
gradle.projectsLoaded {
    rootProject.allprojects.forEach { proj ->
        proj.tasks.withType(org.gradle.api.tasks.compile.JavaCompile::class.java).configureEach {
            val filtered = options.compilerArgs.filterNot { it == "--release" }
            options.compilerArgs.clear()
            options.compilerArgs.addAll(filtered)
        }
    }
}
