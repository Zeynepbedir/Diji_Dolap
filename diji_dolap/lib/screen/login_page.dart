import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'alt_menu.dart'; // Ana menü sayfasına yönlendirme
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  await _auth.signInWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                  // Başarılı giriş sonrası ana sayfaya yönlendir
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AltMenu()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Giriş başarısız')),
                  );
                }
              },
              child: const Text('Giriş Yap'),
            ),
            TextButton(
              onPressed: () {
                // Kayıt sayfasına yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: const Text("Hesap oluştur"),
            ),
          ],
        ),
      ),
    );
  }
}
