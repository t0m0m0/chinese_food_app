# Flutter ProGuard設定
# 中華料理アプリ「マチアプ」リリースビルド用

# Flutter基本設定
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart関連の保持
-keep class * {
    native <methods>;
}

# リフレクション使用クラスの保持
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Google Maps SDK保護
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }

# HotPepper API通信用のHTTPクライアント保護
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# JSON処理保護（API レスポンス解析用）
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# デバッグ情報削除（リリース用）
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# アプリ固有の設定
-keep class com.example.chinese_food_app.MainActivity { *; }

# 最適化レベル設定
-optimizationpasses 5
-dontpreverify
-verbose

# 未使用コードの除去を有効化
-dontshrink