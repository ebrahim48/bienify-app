plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bienify_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.bienify_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ─── Local backend reachability on a physical phone ──────────────────────────
//
// `ApiConstants.baseUrl` defaults to http://localhost:3500. On a physical phone
// `localhost` is the phone, where nothing listens, so Dio raises a connection
// error and the app maps it to `NoInternetException` — a healthy device reads
// as "no internet" and the backend is never contacted at all.
//
// `adb reverse` points the phone's own localhost back at this machine. It does
// not survive a replug, an `adb kill-server` or a reboot, and `flutter run`
// does not open it. run.ps1 used to be the only thing that did, so launching
// any other way — bare `flutter run`, the IDE's run button, a second terminal —
// reproduced the failure. Opening it here covers every launch path, because
// they all build the APK through Gradle first.
//
// Debug and profile only: a release build talks to a real host over HTTPS.
val bienifyApiPort: String =
    (project.findProperty("bienifyApiPort") as String?)
        ?: System.getenv("BIENIFY_API_PORT")
        ?: "3500"

val openBienifyApiTunnel = tasks.register("openBienifyApiTunnel") {
    description = "Points each attached device's localhost:$bienifyApiPort at this machine."
    // The tunnel is external state that expires on its own, so a cached
    // "up to date" verdict would skip exactly the runs that need it.
    outputs.upToDateWhen { false }

    doLast {
        val backslash = 92.toChar().toString()

        // local.properties is a java.util.Properties file, so its values are
        // escaped: on Windows sdk.dir reads C\:\\Android\\Sdk. Unescaping the
        // two sequences a path can contain is cheaper than importing
        // Properties into a script where `java` already names the Java plugin
        // extension.
        val sdkDir: String? = System.getenv("ANDROID_HOME")
            ?: System.getenv("ANDROID_SDK_ROOT")
            ?: rootProject.file("local.properties")
                .takeIf { it.exists() }
                ?.readLines()
                ?.firstOrNull { it.startsWith("sdk.dir=") }
                ?.substringAfter('=')
                ?.replace(backslash + ":", ":")
                ?.replace(backslash + backslash, backslash)
                ?.trim()

        val exe = if (System.getProperty("os.name").startsWith("Windows")) "adb.exe" else "adb"
        val adbPath = sdkDir
            ?.let { File(it, "platform-tools/" + exe) }
            ?.takeIf { it.exists() }
            ?.absolutePath
            ?: exe

        fun adb(vararg args: String): Pair<Int, String> = try {
            val p = ProcessBuilder(listOf(adbPath) + args)
                .redirectErrorStream(true)
                .start()
            val out = p.inputStream.bufferedReader().readText()
            p.waitFor()
            p.exitValue() to out
        } catch (e: Exception) {
            // A missing adb must not fail the build: `flutter build apk` on a
            // machine with no platform-tools installed is a legitimate thing
            // to do.
            -1 to (e.message ?: "adb not found")
        }

        val (code, listing) = adb("devices")
        if (code != 0) {
            logger.lifecycle("bienify: could not run adb (" + listing.trim() + ") - no tunnel opened.")
            return@doLast
        }

        // `adb devices` prints "<serial>\t<state>" under a header line. Only a
        // device in state "device" can be tunnelled - "unauthorized" and
        // "offline" cannot, and asking would just print an error per build.
        val serials = listing.lineSequence()
            .drop(1)
            .map { line -> line.trim().split('\t', ' ').filter { it.isNotEmpty() } }
            .filter { it.size == 2 && it[1] == "device" }
            .map { it[0] }
            .toList()

        if (serials.isEmpty()) return@doLast

        val quoted = 34.toChar()
        serials.forEach { serial ->
            val (rc, msg) = adb("-s", serial, "reverse", "tcp:" + bienifyApiPort, "tcp:" + bienifyApiPort)
            if (rc != 0) {
                logger.lifecycle(
                    "bienify: adb reverse failed on " + serial + " (" + msg.trim() + "). The app will " +
                        "report " + quoted + "no internet" + quoted + " until port " + bienifyApiPort +
                        " is tunnelled."
                )
            } else {
                logger.lifecycle(
                    "bienify: " + serial + " localhost:" + bienifyApiPort + " tunnelled to this machine."
                )
            }
        }
    }
}

tasks.matching { it.name == "preDebugBuild" || it.name == "preProfileBuild" }
    .configureEach { dependsOn(openBienifyApiTunnel) }
