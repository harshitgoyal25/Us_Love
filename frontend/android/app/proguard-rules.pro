# Rules to ignore warnings from com.google.crypto.tink used by flutter_secure_storage
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.crypto.tink.**
-keep class com.google.crypto.tink.** { *; }
