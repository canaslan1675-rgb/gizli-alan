package com.offerforge.gizlialan

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * "Delete original after import" (Pro, #37).
 *
 * `pick` opens the system document picker (ACTION_OPEN_DOCUMENT, read+write
 * grant for the picked items only), copies each pick into the app cache and
 * returns {uri, path, name, mime}. Dart encrypts the copy into the vault,
 * reads it back, and only then calls `deleteOriginals` with the URIs whose
 * encrypted copy was confirmed.
 *
 * `deleteOriginals`, per URI:
 *  - media item on Android 11+ → collected into ONE
 *    MediaStore.createDeleteRequest (system confirmation dialog);
 *  - otherwise DocumentsContract.deleteDocument (SAF, uses the grant);
 *  - Android 10 media fallback: ContentResolver.delete, and on
 *    RecoverableSecurityException the system's userAction dialog, then retry.
 * No storage permission is used (no MANAGE_EXTERNAL_STORAGE).
 * Result: {deleted, failed, declined}.
 */
object ImportChannel {
    const val NAME = "gizlialan/import"
    private const val REQ_PICK = 7301
    private const val REQ_DELETE = 7302
    private const val REQ_RECOVER = 7303

    private var pickResult: MethodChannel.Result? = null
    private var deleteResult: MethodChannel.Result? = null
    private var deleted = 0
    private var failed = 0
    private var declined = false
    private var mediaBatch: List<Uri> = emptyList()
    private var recoverQueue = ArrayDeque<Uri>()

    fun attach(activity: Activity, messenger: BinaryMessenger): MethodChannel {
        val channel = MethodChannel(messenger, NAME)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pick" -> {
                    if (pickResult != null) {
                        result.error("busy", "picker already open", null)
                        return@setMethodCallHandler
                    }
                    val images = call.argument<Boolean>("images") ?: false
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = if (images) "image/*" else "*/*"
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                        addFlags(
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                        )
                    }
                    pickResult = result
                    try {
                        @Suppress("DEPRECATION")
                        activity.startActivityForResult(intent, REQ_PICK)
                    } catch (e: Exception) {
                        pickResult = null
                        result.success(emptyList<Map<String, Any?>>())
                    }
                }
                "deleteOriginals" -> {
                    if (deleteResult != null) {
                        result.error("busy", "delete already running", null)
                        return@setMethodCallHandler
                    }
                    val uris = (call.argument<List<String>>("uris") ?: emptyList())
                        .map { Uri.parse(it) }
                    deleteResult = result
                    startDelete(activity, uris)
                }
                "clearCache" -> {
                    File(activity.cacheDir, "import_src").deleteRecursively()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        return channel
    }

    /** Returns true if the request code belonged to this channel. */
    fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            REQ_PICK -> {
                val result = pickResult ?: return true
                pickResult = null
                val uris = mutableListOf<Uri>()
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val clip = data.clipData
                    if (clip != null) {
                        for (i in 0 until clip.itemCount) uris += clip.getItemAt(i).uri
                    } else {
                        data.data?.let { uris += it }
                    }
                }
                Thread {
                    val out = uris.mapIndexedNotNull { i, u -> copyToCache(activity, u, i) }
                    activity.runOnUiThread { result.success(out) }
                }.start()
            }
            REQ_DELETE -> {
                if (resultCode == Activity.RESULT_OK) {
                    deleted += mediaBatch.size
                } else {
                    failed += mediaBatch.size
                    declined = true
                }
                mediaBatch = emptyList()
                finishDelete()
            }
            REQ_RECOVER -> {
                val uri = recoverQueue.removeFirstOrNull()
                if (uri != null) {
                    if (resultCode == Activity.RESULT_OK && deleteMedia(activity, uri)) {
                        deleted++
                    } else {
                        failed++
                        if (resultCode != Activity.RESULT_OK) declined = true
                    }
                }
                nextRecover(activity)
            }
            else -> return false
        }
        return true
    }

    private fun copyToCache(activity: Activity, uri: Uri, index: Int): Map<String, Any?>? = try {
        val resolver = activity.contentResolver
        var name = "file"
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst() && !c.isNull(0)) name = c.getString(0)
        }
        val dir = File(activity.cacheDir, "import_src").apply { mkdirs() }
        val safe = name.replace(Regex("[/\\\\]"), "_")
        val file = File(dir, "${System.nanoTime()}_${index}_$safe")
        resolver.openInputStream(uri)!!.use { input ->
            file.outputStream().use { input.copyTo(it) }
        }
        mapOf(
            "uri" to uri.toString(),
            "path" to file.absolutePath,
            "name" to name,
            "mime" to resolver.getType(uri),
        )
    } catch (e: Exception) {
        null
    }

    private fun startDelete(activity: Activity, uris: List<Uri>) {
        deleted = 0
        failed = 0
        declined = false
        val media = mutableListOf<Uri>()
        val recover = ArrayDeque<Uri>()
        for (u in uris) {
            val mediaUri = if (Build.VERSION.SDK_INT >= 29) {
                try { MediaStore.getMediaUri(activity, u) } catch (e: Exception) { null }
            } else {
                null
            }
            if (mediaUri != null && Build.VERSION.SDK_INT >= 30) {
                media += mediaUri
                continue
            }
            if (deleteDocument(activity, u)) {
                deleted++
            } else if (mediaUri != null) {
                // Android 10 media item.
                try {
                    if (activity.contentResolver.delete(mediaUri, null, null) > 0) deleted++ else failed++
                } catch (e: SecurityException) {
                    if (Build.VERSION.SDK_INT >= 29 && e is RecoverableSecurityException) {
                        recover += mediaUri
                    } else {
                        failed++
                    }
                }
            } else {
                failed++
            }
        }
        if (media.isNotEmpty() && Build.VERSION.SDK_INT >= 30) {
            mediaBatch = media
            recoverQueue = recover
            try {
                val pi = MediaStore.createDeleteRequest(activity.contentResolver, media)
                @Suppress("DEPRECATION")
                activity.startIntentSenderForResult(pi.intentSender, REQ_DELETE, null, 0, 0, 0)
                return
            } catch (e: Exception) {
                failed += media.size
                mediaBatch = emptyList()
            }
        }
        recoverQueue = recover
        nextRecover(activity)
    }

    private fun nextRecover(activity: Activity) {
        val uri = recoverQueue.firstOrNull()
        if (uri == null) {
            reply()
            return
        }
        try {
            activity.contentResolver.delete(uri, null, null)
            recoverQueue.removeFirst()
            deleted++
            nextRecover(activity)
        } catch (e: SecurityException) {
            if (Build.VERSION.SDK_INT >= 29 && e is RecoverableSecurityException) {
                try {
                    @Suppress("DEPRECATION")
                    activity.startIntentSenderForResult(
                        e.userAction.actionIntent.intentSender, REQ_RECOVER, null, 0, 0, 0,
                    )
                    return
                } catch (_: Exception) {
                }
            }
            recoverQueue.removeFirst()
            failed++
            nextRecover(activity)
        } catch (e: Exception) {
            recoverQueue.removeFirst()
            failed++
            nextRecover(activity)
        }
    }

    private fun finishDelete() {
        // After the Android 11+ batch, Android 10-style queue is empty.
        reply()
    }

    private fun reply() {
        val r = deleteResult ?: return
        deleteResult = null
        r.success(mapOf("deleted" to deleted, "failed" to failed, "declined" to declined))
    }

    private fun deleteMedia(activity: Activity, uri: Uri): Boolean = try {
        activity.contentResolver.delete(uri, null, null) > 0
    } catch (e: Exception) {
        false
    }

    private fun deleteDocument(activity: Activity, uri: Uri): Boolean = try {
        DocumentsContract.isDocumentUri(activity, uri) &&
            DocumentsContract.deleteDocument(activity.contentResolver, uri)
    } catch (e: Exception) {
        false
    }
}
