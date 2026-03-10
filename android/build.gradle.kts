buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
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

subprojects {
    val configure = {
          tasks.withType<KotlinCompile>().configureEach {
              println("Configuring Kotlin for project: ${project.name}")
              if (project.name == "file_picker") {
                  kotlinOptions {
                      jvmTarget = "11"
                  }
              } else if (project.name == "shared_preferences_android") {
                  kotlinOptions {
                      jvmTarget = "17"
                  }
              } else {
                  kotlinOptions {
                      jvmTarget = "1.8"
                  }
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
