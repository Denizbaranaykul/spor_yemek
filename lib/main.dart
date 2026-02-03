import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  // Not: firebase_options.dart dosyasını oluşturmanız gerekecek
  // flutterfire configure komutu ile oluşturabilirsiniz
  // firebase_options.dart oluşturulduktan sonra şu satırı ekleyin:
  // import 'firebase_options.dart';
  // ve Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform) kullanın
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, // firebase_options.dart oluşturulduktan sonra açın
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Lütfen "flutterfire configure" komutunu çalıştırın ve firebase_options.dart dosyasını oluşturun.');
    // Firebase yapılandırması yoksa uygulama yine de çalışabilir
    // Ancak Firebase özellikleri çalışmayacaktır
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Spor Yemek',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Auth durumunu dinle
        return StreamBuilder(
          stream: authProvider.authStateChanges,
          builder: (context, snapshot) {
            // Yükleniyor durumu
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Kullanıcı giriş yapmışsa ana ekrana yönlendir
            if (snapshot.hasData && snapshot.data != null) {
              return const MainScreen();
            }

            // Giriş yapmamışsa login ekranına yönlendir
            return const LoginScreen();
          },
        );
      },
    );
  }
}
