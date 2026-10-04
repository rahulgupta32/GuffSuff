package com.guffsuff.mobile

import com.guffsuff.mobile.crypto.DeviceIdentityStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val identityExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val store = DeviceIdentityStore(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "guffsuff/native_identity").setMethodCallHandler { call, result ->
            if (call.method != "initializeIdentity") {
                result.notImplemented()
            } else {
                val accountId = call.argument<String>("accountId")
                val deviceId = call.argument<String>("deviceId")
                if (accountId == null || deviceId == null) result.error("INVALID_SCOPE", "Account/device scope required", null)
                else identityExecutor.execute {
                    try {
                        val publicResult = store.initialize(accountId, deviceId)
                        Handler(Looper.getMainLooper()).post { result.success(publicResult) }
                    } catch (_: Throwable) {
                        // Do not expose keystore, native private record or filesystem diagnostics.
                        Handler(Looper.getMainLooper()).post { result.error("IDENTITY_UNAVAILABLE", "Secure identity storage unavailable; recovery may be required", null) }
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        identityExecutor.shutdown()
        super.onDestroy()
    }
}
