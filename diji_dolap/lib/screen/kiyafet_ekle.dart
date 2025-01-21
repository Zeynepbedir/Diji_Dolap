import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http; // HTTP istekleri için

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // jsonDecode için gerekli
import 'package:firebase_auth/firebase_auth.dart';
import 'package:io/ansi.dart';

class KiyafetEkle extends StatefulWidget {
  const KiyafetEkle({super.key});

  @override
  State<KiyafetEkle> createState() => _KiyafetEkleState();
}

class _KiyafetEkleState extends State<KiyafetEkle> {
  File? _image; // Seçilen resmin dosyasının tipini nullable yapıyoruz

  late User? user;
  late String uid;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // FirebaseAuth'tan kullanıcıyı alıyoruz
    user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? '';
  }

  // Fotoğrafı galeriden seçme
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Fotoğrafı kameradan çekme
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      } else {
        // Eğer kullanıcı izin vermezse
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      // Kamera erişimi reddedildiyse
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _classifyImage(BuildContext context) async {
    if (_image == null) {
      print("Resim seçilmedi!");
      return;
    }

    const String apiUrl = "http://10.0.2.2:5000/single_classification";

    try {
      var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
      request.files
          .add(await http.MultipartFile.fromPath("image", _image!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        print("Sınıflandırma Sonucu: $responseBody");

        var responseJson = jsonDecode(responseBody);

        // Tüm API'den gelen verileri al
        List<String> resultDetails =
            List<String>.from(responseJson['result_details'] ?? []);

        String resultStr = responseJson['result_str'] ?? 'defaultResultStr';
        String type = responseJson['type'] ?? 'defaultType';

        print("Result Details: $resultDetails");
        print("Result String: $resultStr");
        print("Type: $type");

        // Geçersiz veri durumu kontrolü
        if (resultStr == "unknown" || type == "unknown") {
          // Geçersiz veri durumu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Geçersiz veri tespit edildi. Lütfen tekrar deneyin."),
              backgroundColor: Colors.red,
            ),
          );
          print("Geçersiz kategori, kaydedilmiyor!");
          return; // Geçersiz veri varsa işlemi sonlandırıyoruz
        }

        // Kategoriyi belirleyip Firebase Storage'a fotoğrafı yükle
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('images/$fileName');

        // Resmi Firebase Storage'a yüklerken await kullanarak işlemin bitmesi beklenir
        firebase_storage.UploadTask uploadTask = storageRef.putFile(_image!);

        // Yükleme tamamlandığında resmi Firebase'den alıp Firestore'a kaydediliyor
        await uploadTask.whenComplete(() async {
          String imageUrl = await storageRef.getDownloadURL();
          print("Resim Firebase Storage'a yüklendi, URL: $imageUrl");

          // Firestore'a kaydetme işlemi
          await FirebaseFirestore.instance
              .collection('kiyafetler')
              .doc(uid)
              .collection(type) // Kategoriyi burada 'type' olarak kaydediyoruz
              .add({
            'imageUrl': imageUrl,
            'resultDetails':
                resultDetails, // result_details verilerini kaydediyoruz
            'resultStr': resultStr, // API'den gelen açıklama
            'type': type, // Tip bilgisi
            'createdAt': Timestamp.now(),
            'userId': uid,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Yüklenen kıyafet kaydedildi."),
            ),
          );

          print("Kıyafet bilgileri Firestore'a kaydedildi");
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
        print("Hata: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
      print("Hata oluştu: $e");
    }
  }

  // Kamera izni verilmediği uyarısını göster
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Kamera İzni Gerekli"),
          content: const Text(
              "Kamera erişim izni verilmedi. Lütfen ayarlardan izni verin."),
          actions: <Widget>[
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

  // Fotoğraf seçme için alt menüyü göster
  void _showImageSourceMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 180,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Galeriden Seç"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Kameradan Çek"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Fotoğrafı düzenleme fonksiyonu
  void _editImage() {
    _showImageSourceMenu();
  }

  void _classifyImageWrapper() {
    _classifyImage(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fotoğrafı arka plan olarak ayarlamak
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/kiyafet_ekle.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap:
                            _showImageSourceMenu, // Fotoğraf kutusuna tıklandığında menüyü aç
                        child: _image == null
                            ? Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Fotoğraf seçmek için tıklayın",
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black87),
                                  ),
                                ),
                              )
                            : Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: FileImage(_image!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // Yükleme ve düzenleme butonları
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _classifyImageWrapper,
                            icon: const Icon(Icons.upload),
                            label: const Text("Dolabıma Ekle"),
                          ),
                          ElevatedButton.icon(
                            onPressed: _editImage,
                            icon: const Icon(Icons.edit),
                            label: const Text("Başka Bir Şeçim Yap"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
