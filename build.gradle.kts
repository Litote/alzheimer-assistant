plugins {
    alias(libs.plugins.sonarqube)
}

// ── SonarQube ──────────────────────────────────────────────────────────────
// Token resolution order (first non-empty value wins):
//   1. System property  — set systemProp.sonar.token=<token> in ~/.gradle/gradle.properties
//   2. Env variable     — SONAR_TOKEN (used by CI)
sonar {
    properties {
        val sonarToken = providers.systemProperty("sonar.token")
            .orElse(providers.environmentVariable("SONAR_TOKEN"))
            .orNull
        if (sonarToken != null) {
            property("sonar.token", sonarToken)
        }

        property(
            "sonar.projectKey",
            providers.gradleProperty("sonar.projectKey").orElse("alzheimer-assistant").get(),
        )
        property(
            "sonar.organization",
            providers.gradleProperty("sonar.organization").orElse("").get(),
        )
        property(
            "sonar.host.url",
            providers.gradleProperty("sonar.host.url").orElse("https://sonarcloud.io").get(),
        )

        // The root project owns GitHub Actions YAML files directly so the IaC
        // GitHub Actions sensor can find them (sensors only see files declared
        // in sonar.sources of their own project level).
        property("sonar.sources", ".github/workflows")
        property("sonar.tests", "")

        // Assign .github/workflows files to the GitHub Actions language so the
        // IaC GitHub Actions sensor picks them up (default patterns are empty).
        // Restrict YAML patterns to avoid a language-conflict on the same file.
        property(
            "sonar.lang.patterns.githubactions",
            ".github/workflows/**/*.yml,.github/workflows/**/*.yaml",
        )
        property("sonar.lang.patterns.yaml", "front/**/*.yaml,front/**/*.yml")

        // Enable the generic YAML/JSON analyzer (disabled by default on SonarCloud)
        property("sonar.featureflag.cloud-security-enable-generic-yaml-and-json-analyzer", "true")
    }
}

// ── Root aggregation ───────────────────────────────────────────────────────

tasks.register("check") {
    group = "verification"
    description = "Runs all checks across all components."
    dependsOn(
        project(":front").tasks.named("frontAnalyze"),
        project(":front").tasks.named("frontTest"),
    )
}

// Ensure coverage is generated before sonar uploads results.
tasks.named("sonar") {
    mustRunAfter(tasks.named("check"))
}

// Convenience task: all checks + sonar in one command.
// Usage: ./gradlew allSonar
val allSonar by tasks.registering {
    group = "verification"
    description = "Runs all checks with coverage across all components, then SonarQube analysis."
    dependsOn(tasks.named("check"), tasks.named("sonar"))
}
