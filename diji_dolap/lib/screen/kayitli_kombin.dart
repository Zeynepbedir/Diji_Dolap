import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class KayitliKombin extends StatefulWidget {
  const KayitliKombin({super.key});

  @override
  State<KayitliKombin> createState() => _KayitliKombinState();
}

class _KayitliKombinState extends State<KayitliKombin> {
  String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLoading = false; // Yükleniyor durumu
  List<String> kombinList = []; // Kombin görselleri için global liste

  // Mevsimi belirler
  String getSeason(DateTime date) {
    int month = date.month;
    if (month >= 3 && month <= 5) {
      return "Spring"; // İlkbahar
    } else if (month >= 6 && month <= 8) {
      return "Summer"; // Yaz
    } else if (month >= 9 && month <= 11) {
      return "Fall"; // Sonbahar
    } else {
      return "Winter"; // Kış
    }
  }

  // Kombin önerisi
  Future<List<String>> suggestCombination() async {
    try {
      String mevsim = getSeason(DateTime.now());

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('kiyafetler')
          .doc(uid)
          .collection('top')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Yeterli üst giyim bulunamadı.");
        return [];
      }

      QuerySnapshot bottomQuerySnapshot = await FirebaseFirestore.instance
          .collection('kiyafetler')
          .doc(uid)
          .collection('bottom')
          .get();

      if (bottomQuerySnapshot.docs.isEmpty) {
        print("Yeterli alt giyim bulunamadı.");
        return [];
      }

      QuerySnapshot shoesQuerySnapshot = await FirebaseFirestore.instance
          .collection('kiyafetler')
          .doc(uid)
          .collection('foot')
          .get();

      if (shoesQuerySnapshot.docs.isEmpty) {
        print("Yeterli ayakkabı bulunamadı.");
        return [];
      }

      // Mevsime uygun kıyafetleri filtrele
      List<DocumentSnapshot> filteredTop = querySnapshot.docs.where((doc) {
        List<dynamic> resultDetails = doc['resultDetails'];
        String itemSeason = resultDetails[3];
        return itemSeason == mevsim;
      }).toList();

      List<DocumentSnapshot> filteredBottom =
          bottomQuerySnapshot.docs.where((doc) {
        List<dynamic> resultDetails = doc['resultDetails'];
        String itemSeason = resultDetails[3];
        return itemSeason == mevsim;
      }).toList();

      List<DocumentSnapshot> filteredShoes =
          shoesQuerySnapshot.docs.where((doc) {
        List<dynamic> resultDetails = doc['resultDetails'];
        String itemSeason = resultDetails[3];
        return itemSeason == mevsim;
      }).toList();

      //İlk olarak mevsime göre filtrelenen liste bilgisinden rastgele kıyafet seçilir
      // Eğer uygun kıyafet yoksa, tüm kıyafetlerden rastgele seç
      Random random = Random();

      var randomTop = filteredTop.isNotEmpty
          ? filteredTop[random.nextInt(filteredTop.length)]
          : querySnapshot.docs[random.nextInt(querySnapshot.docs.length)];
      var randomBottom = filteredBottom.isNotEmpty
          ? filteredBottom[random.nextInt(filteredBottom.length)]
          : bottomQuerySnapshot
              .docs[random.nextInt(bottomQuerySnapshot.docs.length)];
      var randomShoes = filteredShoes.isNotEmpty
          ? filteredShoes[random.nextInt(filteredShoes.length)]
          : shoesQuerySnapshot
              .docs[random.nextInt(shoesQuerySnapshot.docs.length)];

      // Kombin verilerini liste halinde döndür
      String randomTopImage = randomTop['imageUrl'] as String;
      String randomBottomImage = randomBottom['imageUrl'] as String;
      String randomShoesImage = randomShoes['imageUrl'] as String;

      return [randomTopImage, randomBottomImage, randomShoesImage];
    } catch (e) {
      print("Hata oluştu: $e");
      return [];
    }
  }

  void oneri() async {
    setState(() {
      isLoading = true;
    });

    // Kombin önerilerini al
    List<String> kombin = await suggestCombination();

    setState(() {
      isLoading = false;
      kombinList = kombin;
    });

    // Eğer kombin önerisi varsa, göster
    if (kombin.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Kombin Önerisi"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üst giyim görseli
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Image.network(
                      kombin[0],
                      fit: BoxFit
                          .cover, // Resmin içeriği sınırlara göre uyarlanır
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Alt giyim görseli
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Image.network(
                      kombin[1],
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Ayakkabı görseli
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Image.network(
                      kombin[2],
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Kapat"),
              ),
              TextButton(
                onPressed: () {
                  kaydet(); // burada
                  Navigator.of(context).pop();
                },
                child: const Text("Kaydet"),
              ),
            ],
          );
        },
      );
    } else {
      // Eğer kombin önerisi yoksa uyarı göster
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Hata"),
            content: const Text(
                "Kombin oluşturulamadı! Lütfen kıyafetlerinizi kontrol edin."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Tamam"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> kaydet() async {
    if (kombinList.isEmpty) {
      print("Kaydedilecek kombin bulunamadı.");
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection("kombin")
          .doc(uid)
          .collection("kombinList")
          .add({
        'imagetop': kombinList[0],
        'imagebottom': kombinList[1],
        'imagefoot': kombinList[2],
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Firebase'e kaydedildi");
    } catch (e) {
      print("Hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan resmi
          Positioned.fill(
            child: Image.asset(
              "assets/images/kombin.png",
              fit: BoxFit.cover,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("kombin")
                .doc(uid)
                .collection("kombinList")
                .orderBy("createdAt",
                    descending: true) // En yeni sıradan listele
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Kayıtlı Kombin Bulunamadı.",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                );
              }

              var kombinDocs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: kombinDocs.length,
                itemBuilder: (context, index) {
                  var kombin = kombinDocs[index];

                  String topImage = kombin['imagetop'];
                  String bottomImage = kombin['imagebottom'];
                  String shoesImage = kombin['imagefoot'];

                  return Card(
                    color: const Color.fromARGB(255, 238, 233, 231)
                        .withOpacity(0.8), // Arka planın netliğini azalt
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Image.network(topImage,
                                  width: 80, height: 80, fit: BoxFit.cover),
                              Image.network(bottomImage,
                                  width: 80, height: 80, fit: BoxFit.cover),
                              Image.network(shoesImage,
                                  width: 80, height: 80, fit: BoxFit.cover),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: oneri,
        label: const Text("Kombin Önerisi Al"),
        icon: const Icon(Icons.checkroom),
      ),
    );
  }
}
