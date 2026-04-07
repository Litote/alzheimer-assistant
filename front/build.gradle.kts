plugins {
    alias(libs.plugins.sonarqube)
}

// ── Flutter tasks ──────────────────────────────────────────────────────────

val flutterPubGet by tasks.registering(Exec::class) {
    group = "front"
    description = "Installs Flutter dependencies."
    workingDir = projectDir
    commandLine("flutter", "pub", "get", "--enforce-lockfile")
}

val frontAnalyze by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter static analysis."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    commandLine("flutter", "analyze", "--fatal-infos")
}

val frontTest by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter unit and widget tests with coverage."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    // --coverage generates coverage/lcov.info consumed by SonarQube
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
    workingDir = projectDir
    commandLine(
        "flutter", "build", "apk", "--release",
        "--dart-define-from-file=secrets.json",
    )
}

val frontBuildIos by tasks.registering(Exec::class) {
    group = "front"
    description = "Builds the iOS app (simulator, no codesign)."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    commandLine(
        "flutter", "build", "ios",
        "--no-codesign", "--simulator", "--debug",
        "--dart-define-from-file=secrets.json",
    )
}

// ── SonarQube (front module) ───────────────────────────────────────────────
// projectBaseDir = front/ so lcov.info SF paths (lib/...) resolve
// correctly — without this, coverage stays at 0.
sonar {
    properties {
        property("sonar.projectName", "front")
        property("sonar.projectBaseDir", projectDir.absolutePath)
        property("sonar.sources", "lib")
        property("sonar.tests", "test")
        property("sonar.dart.lcov.reportPaths", "coverage/lcov.info")
        property("sonar.exclusions", "**/*.freezed.dart,**/*.g.dart")
        property("sonar.coverage.exclusions", "**/*.freezed.dart,**/*.g.dart,lib/main.dart")
    }
}

// Convenience task: tests + sonar in one command.
val frontSonar by tasks.registering {
    group = "front"
    description = "Runs Flutter tests with coverage then SonarQube analysis."
    dependsOn(frontTest, tasks.named("sonar"))
}
