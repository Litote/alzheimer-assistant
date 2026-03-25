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
//
// Requires the sonar-flutter plugin to be installed on the SonarQube/SonarCloud
// server (marketplace: "Flutter / Dart" by insideapp-oss).
//
// Pass the token via:
//   ./gradlew sonar -Dsonar.token=$SONAR_TOKEN
// or set SONAR_TOKEN in the environment.
//
// Project-specific properties can be overridden in ~/.gradle/gradle.properties:
//   sonar.projectKey=alzheimer-assistant
//   sonar.organization=your-sonarcloud-org

sonar {
    properties {
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

        // Flutter source paths
        property("sonar.sources", "front/lib")
        property("sonar.tests", "front/test")

        // Coverage report produced by `flutter test --coverage`
        property("sonar.dart.lcov.reportPaths", "front/coverage/lcov.info")

        // Exclude Freezed / json_serializable generated files
        property("sonar.exclusions", "**/*.freezed.dart,**/*.g.dart")
        property("sonar.coverage.exclusions", "**/*.freezed.dart,**/*.g.dart,front/lib/main.dart")
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
