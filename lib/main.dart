import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:your_project_name/screen/main_screen.dart';
import 'firebase_options.dart'; // FlutterFire CLI ile oluşturulan Firebase ayar dosyası
import 'screen/main_scaffold.dart';
import 'screen/login_screen.dart'; // Login ekranını ekliyoruz
import 'screen/register_screen.dart';
import 'screen/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitap Sat',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: AuthWrapper(), // Giriş durumuna göre ekran gösterilecek
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(), // Register ekranı
        '/main': (context) => MainScreen(
              favourites: [], // Örnek olarak boş bir liste
              onToggleFavourite: (favourite) {
                // Favori işlem mantığı
              },
            ),
        '/scaffold': (context) => MainScaffold(selectedIndex: 0),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Kullanıcı giriş yaptıysa MainScaffold ekranına yönlendir
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainScaffold(selectedIndex: 0); // Ana ekran
        }

        // Giriş yapılmadıysa LoginScreen'e yönlendir
        return const LoginScreen();
      },
    );
  }
}
