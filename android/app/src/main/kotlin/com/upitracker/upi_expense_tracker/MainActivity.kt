package com.upitracker.upi_expense_tracker

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.upitracker/upi"
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Verified UPI wallet packages only — no messengers/social apps. */
    private val upiWalletPackages = listOf(
        "com.google.android.apps.nbu.paisa.user",
        "com.phonepe.app",
        "net.one97.paytm",
        "com.dreamplug.androidapp",
        "money.jupiter",
        "in.org.npci.upiapp",
        "in.amazon.mShop.android.shopping",
        "com.mobikwik_new",
        "com.freecharge.android",
        "com.csam.icici.bank.imobile",
        "com.sbi.lotusintouch",
        "com.myairtelapp",
        "com.axis.mobile",
        "com.snapwork.hdfc",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledUpiApps" -> {
                        val installed = upiWalletPackages.filter { isPackageInstalled(it) }
                        result.success(installed)
                    }
                    "launchUpiIntent" -> {
                        val uri = call.argument<String>("uri")
                        val pkg = call.argument<String>("package")
                        @Suppress("UNUSED_VARIABLE")
                        val appId = call.argument<String>("appId")
                        if (uri == null || pkg.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        runOnMain {
                            result.success(launchUpiExplicit(uri, pkg))
                        }
                    }
                    "launchUpiChooser" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        runOnMain {
                            result.success(launchUpiChooser(uri))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post(block)
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun queryFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PackageManager.MATCH_ALL
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_RESOLVED_FILTER
        }
    }

    /**
     * Opens UPI in the selected wallet. [Intent.setPackage] prevents WhatsApp intercept.
     */
    private fun launchUpiExplicit(uri: String, packageName: String): Boolean {
        if (!isPackageInstalled(packageName)) return false

        val parsed = Uri.parse(uri)

        // 1) Package-targeted VIEW intent (GPay, PhonePe, Paytm, …)
        val targeted = Intent(Intent.ACTION_VIEW, parsed).apply {
            setPackage(packageName)
            addCategory(Intent.CATEGORY_DEFAULT)
        }
        if (canResolve(targeted)) {
            return startSafely(targeted)
        }

        // 2) Explicit component for that package
        val handlers = packageManager.queryIntentActivities(
            Intent(Intent.ACTION_VIEW, parsed),
            queryFlags(),
        ).filter { it.activityInfo.packageName == packageName }

        for (resolve in handlers) {
            val explicit = Intent(Intent.ACTION_VIEW, parsed).apply {
                setClassName(
                    resolve.activityInfo.packageName,
                    resolve.activityInfo.name,
                )
                addCategory(Intent.CATEGORY_DEFAULT)
            }
            if (startSafely(explicit)) return true
        }

        // 3) Generic VIEW + package (some OEM builds)
        val fallback = Intent(Intent.ACTION_VIEW, parsed).apply {
            setPackage(packageName)
        }
        return startSafely(fallback)
    }

    private fun canResolve(intent: Intent): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.resolveActivity(
                intent,
                PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()),
            ) != null
        } else {
            @Suppress("DEPRECATION")
            packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null
        }
    }

    private fun startSafely(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun launchUpiChooser(uri: String): Boolean {
        val parsed = Uri.parse(uri)
        val probe = Intent(Intent.ACTION_VIEW, parsed).apply {
            addCategory(Intent.CATEGORY_DEFAULT)
        }
        val handlers = packageManager.queryIntentActivities(probe, queryFlags())
            .filter { upiWalletPackages.contains(it.activityInfo.packageName) }

        if (handlers.isEmpty()) return false
        if (handlers.size == 1) {
            return launchUpiExplicit(uri, handlers[0].activityInfo.packageName)
        }

        val intents = handlers.map { resolve ->
            Intent(Intent.ACTION_VIEW, parsed).apply {
                setClassName(resolve.activityInfo.packageName, resolve.activityInfo.name)
            }
        }

        return try {
            val chooser = Intent.createChooser(intents.first(), "Pay with UPI").apply {
                if (intents.size > 1) {
                    putExtra(
                        Intent.EXTRA_INITIAL_INTENTS,
                        intents.drop(1).toTypedArray(),
                    )
                }
            }
            startActivity(chooser)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }
}
