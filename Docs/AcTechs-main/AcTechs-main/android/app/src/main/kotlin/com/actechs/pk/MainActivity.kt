package com.actechs.pk

import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		Log.i("AC_TECHS_STARTUP", "MainActivity onCreate: native launch started")
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			splashScreen.setOnExitAnimationListener { splashScreenView ->
				splashScreenView.remove()
			}
		}
		super.onCreate(savedInstanceState)
		Log.i("AC_TECHS_STARTUP", "MainActivity onCreate: FlutterActivity created")
	}
}