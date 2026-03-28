plugins {
    alias(libs.plugins.sonarqube)
}

val flutterDir = file("front")

// ── Flutter tasks ──────────────────────────────────────────────────────────

val flutterPubGet by tasks.registering(Exec::class) {
    group = "front"
    description = "Installs Flutter dependencies."
    workingDir = flutterDir
    commandLine("flutter", "pub", "get", "--enforce-lockfile")
}

val frontAnalyze by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter static analysis."
    dependsOn(flutterPubGet)
    workingDir = flutterDir
    commandLine("flutter", "analyze", "--fatal-infos")
}

val frontTest by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter unit and widget tests with coverage."
    dependsOn(flutterPubGet)
    workingDir = flutterDir
    // --coverage generates front/coverage/lcov.info consumed by SonarQube
    commandLine(
        "flutter", "test", "test/",
        "--exclude-tags", "golden",
        "--coverage",
    )
}

val frontBuildAndroid by tasks.registering(Exec::class) {
    group = "front"
    description = "Builds the Android APK (release)."
    dependsOn(flutterPubGet)
    workingDir = flutterDir
    commandLine(
        "flutter", "build", "apk", "--release",
        "--dart-define-from-file=secrets.json",
    )
}

val frontBuildIos by tasks.registering(Exec::class) {
    group = "front"
    description = "Builds the iOS app (simulator, no codesign)."
    dependsOn(flutterPubGet)
    workingDir = flutterDir
    commandLine(
        "flutter", "build", "ios",
        "--no-codesign", "--simulator", "--debug",
        "--dart-define-from-file=secrets.json",
    )
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

        // Multi-module: the front sub-module sets projectBaseDir=front/ so that
        // LCOV SF paths (lib/...) resolve correctly — without this, coverage
        // stays at 0.
        // The root project owns GitHub Actions YAML files directly so the IaC
        // GitHub Actions sensor can find them (sensors only see files declared
        // in sonar.sources of their own project level).
        property("sonar.sources", ".github/workflows")
        property("sonar.tests", "")
        property("sonar.modules", "front")

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

        // ── front module (Flutter/Dart) ───────────────────────────────────────
        // projectBaseDir = front/ so lcov.info SF paths (lib/...) resolve
        // correctly — without this, coverage stays at 0.
        property("front.sonar.projectName", "front")
        property("front.sonar.projectBaseDir", flutterDir.absolutePath)
        property("front.sonar.sources", "lib")
        property("front.sonar.tests", "test")
        property("front.sonar.dart.lcov.reportPaths", "coverage/lcov.info")
        property("front.sonar.exclusions", "**/*.freezed.dart,**/*.g.dart")
        property("front.sonar.coverage.exclusions", "**/*.freezed.dart,**/*.g.dart,lib/main.dart")
    }
}

// Ensure tests (and therefore the coverage report) run before sonar uploads results.
tasks.named("sonar") {
    mustRunAfter(frontTest)
}

// Convenience task: tests + sonar in one command.
val frontSonar by tasks.registering {
    group = "front"
    description = "Runs Flutter tests with coverage then SonarQube analysis."
    dependsOn(frontTest, tasks.named("sonar"))
}

// ── Root aggregation ───────────────────────────────────────────────────────

tasks.register("check") {
    group = "verification"
    description = "Runs all checks across all components."
    dependsOn(frontAnalyze, frontTest)
}
