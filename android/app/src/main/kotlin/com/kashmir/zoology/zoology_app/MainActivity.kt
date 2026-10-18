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
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
    }
}
