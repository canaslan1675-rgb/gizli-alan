# TikTok Business (App Events) SDK — keep rules from the official guide.
-keep class com.tiktok.** { *; }
-keep class com.android.billingclient.api.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class com.android.installreferrer.** { *; }
-dontwarn com.tiktok.**
# AppMetrica ships its own consumer rules (io.appmetrica.analytics).
# Native channels (Joi voice/AI, updates, second phone): keep our own classes
# so MethodChannel handlers / listeners are never stripped or renamed.
-keep class com.offerforge.gizlialan.** { *; }
