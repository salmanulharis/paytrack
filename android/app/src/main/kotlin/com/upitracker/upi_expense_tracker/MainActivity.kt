package com.upitracker.upi_expense_tracker

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
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
                        val uri = call.argument<String>("uri")
                            ?: "upi://pay?pa=merchant@upi&pn=Merchant&am=1.00&cu=INR"
                        val installed = upiWalletPackages.filter { pkg ->
                            isPackageInstalled(pkg) && canPackageHandleUpi(pkg, uri)
                        }
                        result.success(installed)
                    }
                    "launchUpiIntent" -> {
                        val uri = call.argument<String>("uri")
                        val pkg = call.argument<String>("package")
                        if (uri == null || pkg.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(launchUpiExplicit(uri, pkg))
                    }
                    "launchUpiChooser" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(launchUpiChooser(uri))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    /**
     * Ensures the package itself resolves the UPI URI — prevents WhatsApp/other apps
     * from appearing as "installed UPI" when they only register generic deep links.
     */
    private fun canPackageHandleUpi(packageName: String, uri: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            setPackage(packageName)
            addCategory(Intent.CATEGORY_DEFAULT)
            addCategory(Intent.CATEGORY_BROWSABLE)
        }
        val handlers = packageManager.queryIntentActivities(
            intent,
            PackageManager.MATCH_DEFAULT_ONLY,
        )
        return handlers.any { resolve ->
            resolve.activityInfo.packageName == packageName
        }
    }

    /**
     * Launch UPI only in the requested package. Never falls back to chooser or another app.
     */
    private fun launchUpiExplicit(uri: String, packageName: String): Boolean {
        if (!isPackageInstalled(packageName)) return false
        if (!canPackageHandleUpi(packageName, uri)) return false

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            setPackage(packageName)
            addCategory(Intent.CATEGORY_DEFAULT)
            addCategory(Intent.CATEGORY_BROWSABLE)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    /** User explicitly chose "Other" — show chooser limited to verified wallet apps. */
    private fun launchUpiChooser(uri: String): Boolean {
        val targetIntent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            addCategory(Intent.CATEGORY_DEFAULT)
            addCategory(Intent.CATEGORY_BROWSABLE)
        }

        val handlers = packageManager.queryIntentActivities(
            targetIntent,
            PackageManager.MATCH_DEFAULT_ONLY,
        )

        val allowed = handlers.filter { resolve ->
            upiWalletPackages.contains(resolve.activityInfo.packageName)
        }

        if (allowed.isEmpty()) return false

        val first = allowed.first()
        val launch = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            setClassName(first.activityInfo.packageName, first.activityInfo.name)
            addCategory(Intent.CATEGORY_DEFAULT)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        return try {
            startActivity(launch)
            true
        } catch (_: Exception) {
            false
        }
    }
}
