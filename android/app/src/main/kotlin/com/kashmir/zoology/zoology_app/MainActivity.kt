package com.kashmir.zoology.zoology_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONException

class MainActivity : FlutterActivity() {

    private var pendingSpeciesId: String? = null
    private var navigationChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel: widget data sync
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kashmir.zoology/daily_animal_widget",
        ).setMethodCallHandler { call, result ->
            if (call.method != "setDailyAnimals") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val animalsJson = call.argument<String>("animals")
            if (animalsJson.isNullOrBlank()) {
                result.error("invalid_animals", "Daily animal data is missing.", null)
                return@setMethodCallHandler
            }

            val animals = try {
                JSONArray(animalsJson)
            } catch (error: JSONException) {
                result.error("invalid_animals", "Daily animal data is invalid.", null)
                return@setMethodCallHandler
            }
            if (animals.length() == 0) {
                result.error("invalid_animals", "No daily animal facts were provided.", null)
                return@setMethodCallHandler
            }

            getSharedPreferences(
                DailyAnimalWidgetProvider.PREFERENCES,
                MODE_PRIVATE,
            ).edit().putString(
                DailyAnimalWidgetProvider.ANIMALS_KEY,
                animals.toString(),
            ).apply()

            val widgetIds = AppWidgetManager.getInstance(this).getAppWidgetIds(
                ComponentName(this, DailyAnimalWidgetProvider::class.java),
            )
            if (widgetIds.isNotEmpty()) {
                sendBroadcast(
                    Intent(this, DailyAnimalWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                    },
                )
            }
            result.success(null)
        }

        // Channel: deep-link navigation (widget tap → open species)
        navigationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kashmir.zoology/navigation",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "getInitialSpeciesId") {
                    result.success(pendingSpeciesId)
                    pendingSpeciesId = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val speciesId = intent.getStringExtra(DailyAnimalWidgetProvider.EXTRA_SPECIES_ID)
        if (!speciesId.isNullOrBlank()) {
            intent.removeExtra(DailyAnimalWidgetProvider.EXTRA_SPECIES_ID)
            // If Flutter engine is running, push directly; otherwise buffer it
            val channel = navigationChannel
            if (channel != null) {
                channel.invokeMethod("openSpecies", speciesId)
            } else {
                pendingSpeciesId = speciesId
            }
        }
    }

    override fun onStart() {
        super.onStart()
        // Handle widget tap that cold-started the activity
        val speciesId = intent?.getStringExtra(DailyAnimalWidgetProvider.EXTRA_SPECIES_ID)
        if (!speciesId.isNullOrBlank()) {
            pendingSpeciesId = speciesId
            intent?.removeExtra(DailyAnimalWidgetProvider.EXTRA_SPECIES_ID)
        }
    }
}
