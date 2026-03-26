# Flutter-specific rules — keep entry points used by the embedding.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / Ktor HTTP client
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.ktor.**

# Kotlin coroutines
-keepnames class kotlinx.coroutines.** { *; }
