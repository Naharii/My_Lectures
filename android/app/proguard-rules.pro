# Protect the Notification library from being broken by R8/Proguard
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep enum com.dexterous.flutterlocalnotifications.** { *; }

# Protect Timezone library
-keep class com.google.gson.** { *; }
-keep class com.google.crypto.tink.** { *; }
