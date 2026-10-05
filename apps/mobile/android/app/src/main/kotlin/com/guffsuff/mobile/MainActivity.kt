package com.guffsuff.mobile

import com.guffsuff.mobile.crypto.DeviceIdentityStore
import com.guffsuff.mobile.crypto.NativeCryptoBridge
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
        val bridge = NativeCryptoBridge(DeviceIdentityStore(applicationContext))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "guffsuff/native_identity").setMethodCallHandler { call, result ->
            if (call.method !in NativeCryptoBridge.METHODS) {
                result.notImplemented()
            } else {
                identityExecutor.execute {
                    try {
                        val publicResult = bridge.execute(call.method, call.arguments)
                        Handler(Looper.getMainLooper()).post { result.success(publicResult) }
                    } catch (_: IllegalArgumentException) {
                        Handler(Looper.getMainLooper()).post { result.error("INVALID_CRYPTO_REQUEST", "Invalid encryption request", null) }
                    } catch (_: Throwable) {
                        // Never expose keystore, private records, message contents or filesystem details.
                        Handler(Looper.getMainLooper()).post { result.error("CRYPTO_UNAVAILABLE", "Secure messaging unavailable; recovery may be required", null) }
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
