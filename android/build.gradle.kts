allprojects {
    repositories {
        google()
        mavenCentral()
        // IronSource Maven repository
        maven { url = uri("https://android-sdk.is.com/") }
        // AppLovin Maven repository
        maven { url = uri("https://artifacts.applovin.com/android") }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
