buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
}

import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

fun pluginJvmTarget(projectName: String): String {
    return when (projectName) {
        "app", "package_info_plus", "shared_preferences_android" -> "17"
        "file_picker" -> "11"
        "receive_sharing_intent", "workmanager_android" -> "1.8"
        else -> "17"
    }
}

subprojects {
    val configure = {
          val javaTarget = pluginJvmTarget(project.name)

          tasks.withType<KotlinCompile>().configureEach {
              println("Configuring Kotlin for project: ${project.name} -> JVM $javaTarget")
              kotlinOptions {
                  jvmTarget = javaTarget
              }
          }
      }

    if (state.executed) {
        configure()
    } else {
        afterEvaluate {
            configure()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
