allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(file("${project.projectDir}/../build"))
subprojects {
    project.layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get()}/${project.name}"))
}


subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
            }
        }
    }
}

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                if (project.name == "isar_flutter_libs") {
                    android.namespace = "dev.isar.isar_flutter_libs"
                } else if (project.name == "jni") {
                    android.namespace = "com.example.jni"
                } else {
                    android.namespace = "com.example.${project.name.replace("_", ".")}"
                }
            }
            android.compileSdkVersion("android-36")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
