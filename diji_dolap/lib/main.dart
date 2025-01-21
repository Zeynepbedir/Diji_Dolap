import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screen/alt_menu.dart';
import 'screen/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase başlatma
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(fontFamily: 'Sansita'),
        debugShowCheckedModeBanner: false,
        home: const AuthCheck());
  }
}

// Kullanıcı giriş durumu kontrolü
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(), // Kullanıcı durumunu dinler
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Bekleme durumu
        } else if (snapshot.hasData) {
          return const AltMenu(); // Giriş yapmışsa AltMenu'yu göster
        } else {
          return const LoginPage(); // Giriş yapmamışsa LoginPage'e yönlendir
        }
      },
    );
  }
}
