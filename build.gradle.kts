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
            // No untilBuild: theme-only plugins don't depend on platform APIs that
            // change across versions, so leaving the upper bound open lets the
            // plugin load in future IDE majors without a re-release. The
            // Marketplace rejects magic values like 999.*, so we omit the
            // attribute entirely (which the validator accepts).
            untilBuild = provider { null }
        }
    }

    // Marketplace credentials for the `publishPlugin` task, read from the
    // environment so the token never lands in a tracked file. CI supplies it
    // from the JETBRAINS_PUBLISH_TOKEN secret; locally, export PUBLISH_TOKEN
    // before `./gradlew publishPlugin` if you need to ship by hand.
    //
    // `providers.environmentVariable` rather than `System.getenv` on purpose:
    // gradle.properties turns on the configuration cache, and a raw getenv
    // read at configuration time isn't cache-safe.
    publishing {
        token = providers.environmentVariable("PUBLISH_TOKEN")
    }
}
