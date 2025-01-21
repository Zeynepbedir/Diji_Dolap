import 'package:diji_dolap/screen/alt_menu.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController, // Kullanıcı adı input
              decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Firebase Auth ile kullanıcı kaydet
                  UserCredential userCredential =
                      await _auth.createUserWithEmailAndPassword(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );

                  debugPrint(
                      "Kullanıcı oluşturuldu: ${userCredential.user?.uid}");

                  // Kullanıcı bilgilerini Firestore'a kaydet
                  await _firestore
                      .collection('users')
                      .doc(userCredential.user?.uid)
                      .set({
                    'username': _usernameController.text
                        .trim(), // Kullanıcı adını kaydet
                    'email':
                        _emailController.text.trim(), // E-posta adresini kaydet
                    'createdAt': Timestamp.now(), // Hesap oluşturulma tarihi
                  });

                  debugPrint("Firestore'a kayıt başarılı!");

                  // Kullanıcı oturum kontrolü
                  User? currentUser = _auth.currentUser;
                  if (currentUser != null) {
                    debugPrint("Oturum açıldı: ${currentUser.uid}");
                    // Ana sayfaya yönlendirme
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AltMenu()),
                    );
                  } else {
                    debugPrint("Oturum açma başarısız.");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Oturum açma başarısız! Lütfen tekrar deneyin.")),
                    );
                  }
                } catch (e) {
                  debugPrint("Hata oluştu: $e");

                  // Firebase hatalarını kontrol et
                  String errorMessage = 'Kayıt başarısız';
                  if (e is FirebaseAuthException) {
                    if (e.code == 'email-already-in-use') {
                      errorMessage = 'Bu e-posta zaten kullanılıyor';
                    } else if (e.code == 'weak-password') {
                      errorMessage = 'Şifre çok zayıf';
                    } else if (e.code == 'invalid-email') {
                      errorMessage = 'Geçersiz e-posta formatı';
                    }
                  }

                  // Hata mesajını kullanıcıya göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              },
              child: const Text('Kayıt Ol'),
            ),
            TextButton(
              onPressed: () {
                // Giriş sayfasına yönlendir
                Navigator.pop(context);
              },
              child: const Text("Zaten hesabım var, giriş yap"),
            ),
          ],
        ),
      ),
    );
  }
}
