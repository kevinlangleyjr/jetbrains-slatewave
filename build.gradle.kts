plugins {
    java
    id("org.jetbrains.intellij.platform") version "2.14.0"
}

group = providers.gradleProperty("pluginGroup").get()
version = providers.gradleProperty("pluginVersion").get()

java {
    // IDEA 2024.1 (sinceBuild=241) runs on JDK 17 bytecode; pin the toolchain
    // so the build reproduces regardless of which JDK is invoking Gradle.
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}

repositories {
    mavenCentral()
    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    intellijPlatform {
        create(
            providers.gradleProperty("platformType"),
            providers.gradleProperty("platformVersion"),
        )
    }
}

intellijPlatform {
    // Theme-only plugin: no Java/Kotlin sources, so skip the bytecode-instrumentation pass
    // the plugin runs by default. (Without this, `instrumentCode` fails wanting a Java compiler.)
    instrumentCode = false

    pluginConfiguration {
        name = providers.gradleProperty("pluginName")
        version = providers.gradleProperty("pluginVersion")

        ideaVersion {
            sinceBuild = providers.gradleProperty("pluginSinceBuild")
            untilBuild = providers.gradleProperty("pluginUntilBuild")
        }
    }
}
