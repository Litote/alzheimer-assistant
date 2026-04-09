plugins {
    alias(libs.plugins.sonarqube)
}

// ── Flutter tasks ──────────────────────────────────────────────────────────

// Resolve flutter executable from local.properties if available, fallback to PATH.
val flutterCmd = project.file("android/local.properties").let { propFile ->
    if (propFile.exists()) {
        val props = java.util.Properties()
        propFile.inputStream().use { props.load(it) }
        val sdk = props.getProperty("flutter.sdk")
        if (sdk != null) "$sdk/bin/flutter" else "flutter"
    } else "flutter"
}

val flutterPubGet by tasks.registering(Exec::class) {
    group = "front"
    description = "Installs Flutter dependencies."
    workingDir = projectDir
    commandLine(flutterCmd, "pub", "get", "--enforce-lockfile")
}

val frontAnalyze by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter static analysis."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    commandLine(flutterCmd, "analyze", "--fatal-infos")
}

val frontTest by tasks.registering(Exec::class) {
    group = "front"
    description = "Runs Flutter unit and widget tests with coverage."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    // --coverage generates coverage/lcov.info consumed by SonarQube
    commandLine(
        flutterCmd, "test", "test/",
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
        flutterCmd, "build", "apk", "--release",
        "--dart-define-from-file=secrets.json",
    )
}

val frontBuildIos by tasks.registering(Exec::class) {
    group = "front"
    description = "Builds the iOS app (simulator, no codesign)."
    dependsOn(flutterPubGet)
    workingDir = projectDir
    commandLine(
        flutterCmd, "build", "ios",
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
