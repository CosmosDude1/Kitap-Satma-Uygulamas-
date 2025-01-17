import 'package:flutter/material.dart';

class FavouriteListingsScreen extends StatelessWidget {
  const FavouriteListingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Dış boşluk
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorilerim'),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Favori Ürünler',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Ürün kartlarını içeren bir GridView
              GridView.builder(
                shrinkWrap: true, // Boyutlandırmayı otomatik yap
                physics:
                    const NeverScrollableScrollPhysics(), // Kaydırmayı devre dışı bırak
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 sütun
                  childAspectRatio: 0.8, // Kart oranı
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 10, // Örnek olarak 10 ürün
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // İçerik boyutuna göre ayarlama
                      children: [
                        Container(
                          height: 120,
                          color: Colors.orange[100 * ((index % 6) + 1)],
                          child: Center(child: Text('Ürün ${index + 1}')),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ürün Başlığı ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Fiyat: \$${(index + 1) * 10}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Ürünü sepete ekleme işlemi
                          },
                          child: const Text('Sepete Ekle'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // GridView'den sonra boşluk
            ],
          ),
        ),
      ),
    );
  }
}
