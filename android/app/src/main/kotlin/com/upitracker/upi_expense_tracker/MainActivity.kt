package com.upitracker.upi_expense_tracker

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.upitracker/upi"

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
                        if (uri == null || pkg.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        runOnUiThread {
                            result.success(launchUpiExplicit(uri, pkg))
                        }
                    }
                    "launchUpiChooser" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        runOnUiThread {
                            result.success(launchUpiChooser(uri))
                        }
                    }
                    else -> result.notImplemented()
                }
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

    /**
     * Opens UPI in the selected wallet. Always sets [Intent.setPackage] so WhatsApp
     * and other apps cannot intercept. Does not use a system-wide chooser.
     */
    private fun launchUpiExplicit(uri: String, packageName: String): Boolean {
        if (!isPackageInstalled(packageName)) return false

        val parsed = Uri.parse(uri)

        // 1) Standard package-targeted deep link (works for GPay, PhonePe, Paytm, etc.)
        try {
            val intent = Intent(Intent.ACTION_VIEW, parsed).apply {
                setPackage(packageName)
            }
            startActivity(intent)
            return true
        } catch (_: ActivityNotFoundException) {
            // fall through
        } catch (_: SecurityException) {
            // fall through
        }

        // 2) Explicit activity component inside the wallet package
        val handlers = packageManager.queryIntentActivities(
            Intent(Intent.ACTION_VIEW, parsed),
            PackageManager.MATCH_DEFAULT_ONLY,
        ).filter { resolve ->
            resolve.activityInfo.packageName == packageName
        }

        for (resolve in handlers) {
            try {
                val intent = Intent(Intent.ACTION_VIEW, parsed).apply {
                    setClassName(
                        resolve.activityInfo.packageName,
                        resolve.activityInfo.name,
                    )
                }
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
                continue
            } catch (_: SecurityException) {
                continue
            }
        }

        return false
    }

    /** Limited chooser: only verified wallet apps, never messengers. */
    private fun launchUpiChooser(uri: String): Boolean {
        val parsed = Uri.parse(uri)
        val probe = Intent(Intent.ACTION_VIEW, parsed)
        val handlers = packageManager.queryIntentActivities(
            probe,
            PackageManager.MATCH_DEFAULT_ONLY,
        ).filter { resolve ->
            upiWalletPackages.contains(resolve.activityInfo.packageName)
        }

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
