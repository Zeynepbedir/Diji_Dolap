import 'package:diji_dolap/screen/kiyafet_ekle.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'kayitli_kombin.dart';

class AltMenu extends StatefulWidget {
  const AltMenu({super.key});

  @override
  State<AltMenu> createState() => _AltMenuState();
}

class _AltMenuState extends State<AltMenu> {
  int navBarIndex = 0; // Alt gezinme çubuğu seçimi için

  // Sayfalar listesi
  final List<Widget> pages = [
    const HomePage(),
    const KiyafetEkle(),
    const KayitliKombin(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[navBarIndex], // Seçilen sayfayı göster
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navBarIndex,
        onTap: (index) {
          setState(() {
            navBarIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo_outlined),
            label: 'Kıyafet Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.turned_in_not_rounded),
            label: 'Kombinlerim',
          ),
        ],
      ),
    );
  }
}
