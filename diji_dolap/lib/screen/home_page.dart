import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<String> _categories = [
    "Dolabım",
    "Üst Giyim",
    "Alt Giyim",
    "Ayakkabı"
  ];

  final List<Widget> _categoryContents = [
    Center(child: Text('Dolabım İçeriği', style: TextStyle(fontSize: 20))),
    Center(child: Text('Üst Giyim İçeriği', style: TextStyle(fontSize: 20))),
    Center(child: Text('Alt Giyim İçeriği', style: TextStyle(fontSize: 20))),
    Center(child: Text('Ayakkabı İçeriği', style: TextStyle(fontSize: 20))),
  ];

  late User? user;
  late String uid;
  late String category;
  @override
  void initState() {
    super.initState();
    // FirebaseAuth'tan kullanıcıyı alıyoruz
    user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? ''; // Eğer kullanıcı yoksa boş string atanır
  }

  // Kategori ismini Firestore koleksiyon ismiyle eşleştirme fonksiyonu
  String mapCategoryToFirestore(String category) {
    switch (category) {
      case "Üst Giyim":
        return "top";
      case "Alt Giyim":
        return "bottom";
      case "Ayakkabı":
        return "foot";
      default:
        return "general";
    }
  }

  // "Dolabım" için tüm kategorilerden veriyi çekme
  Future<List<Map<String, dynamic>>> fetchAllClothing(String uid) async {
    try {
      final categories = ["top", "bottom", "foot"];
      List<Map<String, dynamic>> allClothing = [];
      for (String category in categories) {
        CollectionReference categoryRef = FirebaseFirestore.instance
            .collection('kiyafetler')
            .doc(uid)
            .collection(category);
        QuerySnapshot querySnapshot =
            await categoryRef.orderBy('createdAt', descending: true).get();
        allClothing.addAll(querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
      }
      return allClothing;
    } catch (e) {
      print('Hata: $e');
      return [];
    }
  }

  // Belirli bir kategori için veriyi Firestore'dan çekme
  Future<List<Map<String, dynamic>>> fetchCategoryData(
      String uid, String category) async {
    try {
      CollectionReference categoryRef = FirebaseFirestore.instance
          .collection('kiyafetler')
          .doc(uid)
          .collection(category);
      QuerySnapshot querySnapshot =
          await categoryRef.orderBy('createdAt', descending: true).get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Hata: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ana_sayfa.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Image.asset(
              'assets/images/logo.png',
              width: 300,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(
              height: 10,
            ),
            // Kategori Butonları
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _categories.asMap().entries.map((entry) {
                  int index = entry.key;
                  String title = entry.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedIndex == index
                            ? Colors.blue
                            : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _selectedIndex == 0
                    ? fetchAllClothing(uid)
                    : fetchCategoryData(uid,
                        mapCategoryToFirestore(_categories[_selectedIndex])),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Hata: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Bu kategoriye ait veri yok.'));
                  }

                  List<Map<String, dynamic>> data = snapshot.data!;
                  return GridView.builder(
                    padding: EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Bir satırda 3 resim
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      var item = data[index];
                      return GestureDetector(
                        onTap: () {
                          print("Seçilen resim: ${item['imageUrl']}");
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(item['imageUrl'] ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
