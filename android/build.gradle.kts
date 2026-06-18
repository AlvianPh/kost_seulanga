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
    val proj = this
    val configureNamespace = {
        if (proj.hasProperty("android")) {
            val android = proj.extensions.findByName("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val namespace = getNamespace.invoke(android) as String?
                    if (namespace.isNullOrEmpty()) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        setNamespace.invoke(android, "com.example.${proj.name.replace("-", "_").replace(".", "_")}")
                    }
                } catch (e: Exception) {
                    // Ignore reflection errors if methods are not present or inaccessible
                }
            }
        }

        try {
            val manifestFile = proj.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                var content = manifestFile.readText()
                val packageRegex = Regex("""package=["'][^"']*["']""")
                if (content.contains(packageRegex)) {
                    content = content.replace(packageRegex, "")
                    manifestFile.writeText(content)
                }
            }
        } catch (e: Exception) {
            // Ignore if the manifest file cannot be read or written (e.g. read-only)
        }
    }

    if (proj.state.executed) {
        configureNamespace()
    } else {
        proj.afterEvaluate {
            configureNamespace()
        }
    }
}



tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

