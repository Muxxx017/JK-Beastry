package com.kashmir.zoology.zoology_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.Calendar
import java.util.concurrent.Executors

class DailyAnimalWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        if (appWidgetIds.isEmpty()) return
        val pendingResult = goAsync()
        executor.execute {
            try {
                appWidgetIds.forEach { widgetId -> updateWidget(context, widgetId) }
            } finally {
                pendingResult.finish()
            }
        }
    }

    private fun updateWidget(context: Context, widgetId: Int) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val animalsJson = preferences.getString(ANIMALS_KEY, null)
        val manager = AppWidgetManager.getInstance(context)
        val views = RemoteViews(context.packageName, R.layout.daily_animal_widget)
        views.setOnClickPendingIntent(
            R.id.daily_animal_widget,
            PendingIntent.getActivity(
                context,
                widgetId,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )

        if (animalsJson.isNullOrBlank()) {
            views.setTextViewText(R.id.daily_animal_name, "Daily animal")
            views.setTextViewText(
                R.id.daily_animal_fact,
                "Open J&K Bestiary once to load the curated animal facts.",
            )
            views.setTextViewText(R.id.daily_animal_scientific_name, "")
            views.setTextViewText(R.id.daily_animal_photo_credit, "Photo loads when online")
            views.setImageViewResource(
                R.id.daily_animal_photo,
                android.R.drawable.ic_menu_gallery,
            )
            manager.updateAppWidget(widgetId, views)
            return
        }

        val animals = try {
            JSONArray(animalsJson)
        } catch (error: JSONException) {
            Log.e(TAG, "Stored daily animal data is invalid.", error)
            views.setTextViewText(R.id.daily_animal_name, "Daily animal unavailable")
            views.setTextViewText(
                R.id.daily_animal_fact,
                "Open the app to refresh the widget data.",
            )
            manager.updateAppWidget(widgetId, views)
            return
        }
        if (animals.length() == 0) {
            views.setTextViewText(R.id.daily_animal_name, "Daily animal unavailable")
            views.setTextViewText(
                R.id.daily_animal_fact,
                "Open the app to refresh the widget data.",
            )
            manager.updateAppWidget(widgetId, views)
            return
        }

        val animal = animals.getJSONObject(dailyIndex(animals.length()))
        val id = animal.optString("id")
        val commonName = animal.optString("commonName", "Daily animal")
        val scientificName = animal.optString("scientificName")
        val fact = animal.optString("funFact")
        views.setTextViewText(R.id.daily_animal_name, commonName)
        views.setTextViewText(R.id.daily_animal_scientific_name, scientificName)
        views.setTextViewText(R.id.daily_animal_fact, fact)
        views.setContentDescription(
            R.id.daily_animal_photo,
            "$commonName ($scientificName). $fact",
        )

        val cachedPhoto = readCachedPhoto(preferences, id)
        val cachedBitmap = if (cachedPhoto?.canCache == true) {
            readCachedBitmap(context, id)
        } else {
            null
        }
        if (cachedBitmap != null) {
            views.setImageViewBitmap(R.id.daily_animal_photo, cachedBitmap)
        } else {
            views.setImageViewResource(
                R.id.daily_animal_photo,
                android.R.drawable.ic_menu_gallery,
            )
        }
        views.setTextViewText(
            R.id.daily_animal_photo_credit,
            cachedPhoto?.credit ?: "Photo loads when online",
        )
        manager.updateAppWidget(widgetId, views)

        try {
            val photo = findPhoto(scientificName)
            if (photo == null) {
                if (cachedPhoto == null) {
                    views.setTextViewText(
                        R.id.daily_animal_photo_credit,
                        "No reference photo available",
                    )
                    manager.updateAppWidget(widgetId, views)
                }
                return
            }
            val bitmap = downloadBitmap(photo.url)
            views.setImageViewBitmap(R.id.daily_animal_photo, bitmap)
            views.setTextViewText(
                R.id.daily_animal_photo_credit,
                if (photo.canCache) photo.credit else "${photo.credit} · online only",
            )
            manager.updateAppWidget(widgetId, views)
            if (photo.canCache) {
                try {
                    cachePhoto(context, preferences, id, photo, bitmap)
                } catch (error: IOException) {
                    Log.e(TAG, "Could not cache the daily animal photo.", error)
                }
            }
        } catch (error: IOException) {
            Log.w(TAG, "Could not refresh the daily animal photo.", error)
            if (cachedBitmap == null) {
                views.setTextViewText(
                    R.id.daily_animal_photo_credit,
                    "Photo unavailable offline",
                )
                manager.updateAppWidget(widgetId, views)
            }
        } catch (error: JSONException) {
            Log.w(TAG, "iNaturalist returned invalid daily photo data.", error)
            if (cachedBitmap == null) {
                views.setTextViewText(
                    R.id.daily_animal_photo_credit,
                    "Photo unavailable",
                )
                manager.updateAppWidget(widgetId, views)
            }
        }
    }

    private fun dailyIndex(size: Int): Int {
        val today = Calendar.getInstance()
        val dayNumber = today.get(Calendar.YEAR).toLong() * 366L +
            today.get(Calendar.DAY_OF_YEAR)
        return Math.floorMod(dayNumber, size.toLong()).toInt()
    }

    @Throws(IOException::class, JSONException::class)
    private fun findPhoto(scientificName: String): Photo? {
        val query = URLEncoder.encode(scientificName, Charsets.UTF_8.name())
        val response = readUrl(
            "https://api.inaturalist.org/v1/taxa/autocomplete?q=$query&rank=species&per_page=10",
        )
        val results = JSONObject(response).getJSONArray("results")
        for (index in 0 until results.length()) {
            val taxon = results.getJSONObject(index)
            if (!taxon.optString("name").equals(scientificName, ignoreCase = true)) {
                continue
            }
            val photo = taxon.optJSONObject("default_photo") ?: return null
            val photoUrl = photo.optString("medium_url").ifBlank {
                photo.optString("url")
            }
            if (!photoUrl.startsWith("https://")) return null
            return Photo(
                url = photoUrl,
                attribution = photo.optString("attribution"),
                license = photo.optString("license_code"),
            )
        }
        return null
    }

    @Throws(IOException::class)
    private fun downloadBitmap(photoUrl: String): Bitmap {
        val bytes = readUrlBytes(photoUrl, MAX_PHOTO_BYTES)
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: throw IOException("The reference photo could not be decoded.")
    }

    @Throws(IOException::class)
    private fun readUrl(url: String): String =
        readUrlBytes(url, MAX_RESPONSE_BYTES).toString(Charsets.UTF_8)

    @Throws(IOException::class)
    private fun readUrlBytes(url: String, maxBytes: Int): ByteArray {
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = NETWORK_TIMEOUT_MS
        connection.readTimeout = NETWORK_TIMEOUT_MS
        connection.setRequestProperty("User-Agent", "JandKBestiary/1.0")
        return try {
            if (connection.responseCode !in 200..299) {
                throw IOException("Photo source returned HTTP ${connection.responseCode}.")
            }
            if (connection.contentLength > maxBytes) {
                throw IOException("The iNaturalist response is larger than expected.")
            }
            connection.inputStream.use { input ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                while (true) {
                    val bytesRead = input.read(buffer)
                    if (bytesRead < 0) break
                    if (output.size() + bytesRead > maxBytes) {
                        throw IOException("The iNaturalist response is larger than expected.")
                    }
                    output.write(buffer, 0, bytesRead)
                }
                output.toByteArray()
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun cachePhoto(
        context: Context,
        preferences: android.content.SharedPreferences,
        id: String,
        photo: Photo,
        bitmap: Bitmap,
    ) {
        val cacheFile = cacheFile(context, id)
        val directory = cacheFile.parentFile
        if (directory != null && !directory.exists() && !directory.mkdirs()) {
            throw IOException("The daily animal photo folder could not be created.")
        }
        cacheFile.outputStream().use { output ->
            if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 85, output)) {
                throw IOException("The daily animal photo could not be cached.")
            }
        }
        preferences.edit().putString(photoPreferenceKey(id), photo.toJson()).apply()
    }

    private fun readCachedPhoto(
        preferences: android.content.SharedPreferences,
        id: String,
    ): Photo? {
        val json = preferences.getString(photoPreferenceKey(id), null) ?: return null
        return try {
            Photo.fromJson(JSONObject(json))
        } catch (error: JSONException) {
            Log.w(TAG, "Cached daily animal photo details are invalid.", error)
            null
        }
    }

    private fun readCachedBitmap(context: Context, id: String): Bitmap? {
        val file = cacheFile(context, id)
        return if (file.isFile) BitmapFactory.decodeFile(file.absolutePath) else null
    }

    private fun cacheFile(context: Context, id: String): File {
        val safeId = id.hashCode().toString().replace("-", "n")
        return File(
            File(context.filesDir, "daily-animal-photos"),
            "daily-animal-$safeId.jpg",
        )
    }

    private fun photoPreferenceKey(id: String) = "photo-${id.hashCode()}"

    private data class Photo(
        val url: String,
        val attribution: String,
        val license: String,
    ) {
        val credit: String
            get() = listOf(
                attribution.ifBlank { "iNaturalist photo" },
                "License: ${license.ifBlank { "unspecified" }}",
            ).joinToString(" · ")
        val canCache: Boolean
            get() {
                val normalized = license.trim().lowercase()
                return normalized == "cc-by" ||
                    normalized.matches(Regex("cc-by-[0-9.]+")) ||
                    normalized == "cc0" ||
                    normalized == "public-domain"
            }

        fun toJson() = JSONObject()
            .put("url", url)
            .put("attribution", attribution)
            .put("license", license)
            .toString()

        companion object {
            @Throws(JSONException::class)
            fun fromJson(json: JSONObject) = Photo(
                url = json.getString("url"),
                attribution = json.optString("attribution"),
                license = json.optString("license"),
            )
        }
    }

    companion object {
        const val PREFERENCES = "daily_animal_widget"
        const val ANIMALS_KEY = "animals_json"
        private const val TAG = "DailyAnimalWidget"
        private const val NETWORK_TIMEOUT_MS = 10000
        private const val MAX_RESPONSE_BYTES = 2 * 1024 * 1024
        private const val MAX_PHOTO_BYTES = 5 * 1024 * 1024
        private val executor = Executors.newSingleThreadExecutor()
    }
}
