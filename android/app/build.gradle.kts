plugins {
    id("com.android.application")
    id("kotlin-android")
    // O plugin do Flutter deve vir depois do Android e Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gerenciasallex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Especifique seu Application ID único aqui
        applicationId = "com.example.gerenciasallex"
        
        // Você pode atualizar os valores abaixo conforme necessário
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Adicione sua configuração de assinatura para release.
            // Assinando com a chave de debug por enquanto para testes.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}