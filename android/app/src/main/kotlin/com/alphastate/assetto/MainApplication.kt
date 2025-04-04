package com.alphastate.assetto

import io.flutter.app.FlutterApplication
import com.google.firebase.FirebaseApp

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
} 