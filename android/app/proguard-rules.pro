# TikTok Business (App Events) SDK — keep rules from the official guide.
-keep class com.tiktok.** { *; }
-keep class com.android.billingclient.api.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class com.android.installreferrer.** { *; }
-dontwarn com.tiktok.**
# AppMetrica ships its own consumer rules (io.appmetrica.analytics).
