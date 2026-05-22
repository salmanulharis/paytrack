package com.upitracker.upi_expense_tracker

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.upitracker/upi"

    private val upiPackages = listOf(
        "com.google.android.apps.nbu.paisa.user",
        "com.phonepe.app",
        "net.one97.paytm",
        "com.dreamplug.androidapp",
        "money.jupiter",
        "in.org.npci.upiapp",
        "in.amazon.mShop.android.shopping",
        "com.whatsapp",
        "com.mobikwik_new",
        "com.freecharge.android",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledUpiApps" -> {
                        val installed = mutableListOf<String>()
                        val pm = packageManager
                        for (pkg in upiPackages) {
                            try {
                                pm.getPackageInfo(pkg, 0)
                                installed.add(pkg)
                            } catch (_: PackageManager.NameNotFoundException) {
                            }
                        }
                        result.success(installed)
                    }
                    "launchUpiIntent" -> {
                        val uri = call.argument<String>("uri")
                        val pkg = call.argument<String>("package")
                        if (uri == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(launchUpi(uri, pkg))
                    }
                    "launchUpiChooser" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(launchChooser(uri))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchUpi(uri: String, packageName: String?): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri))
            if (!packageName.isNullOrEmpty()) {
                intent.setPackage(packageName)
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            launchChooser(uri)
        }
    }

    private fun launchChooser(uri: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri))
            startActivity(Intent.createChooser(intent, "Pay with"))
            true
        } catch (e: Exception) {
            false
        }
    }
}
