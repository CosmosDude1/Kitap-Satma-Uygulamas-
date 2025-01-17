import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Destek'),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Destek Merkezi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 20),

              // Sıkça Sorulan Sorular
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sıkça Sorulan Sorular',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildFaqItem(
                      question: 'Siparişim ne zaman kargoya verilir?',
                      answer:
                          'Siparişler genellikle 2-3 iş günü içinde kargoya verilir.',
                    ),
                    _buildFaqItem(
                      question: 'İade süreci nasıl işler?',
                      answer:
                          'Ürün teslim alındıktan sonra 14 gün içerisinde iade edilebilir.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // İletişim Seçenekleri
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.chat, color: Colors.deepOrange),
                      title: const Text('Canlı Destek ile İletişime Geç'),
                      trailing: Icon(Icons.arrow_forward_ios,
                          color: Colors.deepOrange.withOpacity(0.5)),
                      onTap: () {
                        // Canlı destek açma işlemi
                      },
                    ),
                    Divider(color: Colors.deepOrange.withOpacity(0.1)),
                    ListTile(
                      leading:
                          Icon(Icons.support_agent, color: Colors.deepOrange),
                      title: const Text('Destek Talebi Gönder'),
                      trailing: Icon(Icons.arrow_forward_ios,
                          color: Colors.deepOrange.withOpacity(0.5)),
                      onTap: () {
                        // Destek talebi gönderme işlemi
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // İletişim Bilgileri
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İletişim Bilgileri',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.phone, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text('Telefon: +90 555 555 5555'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.email, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text('E-posta: destek@ornek.com'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.light(primary: Colors.deepOrange),
      ),
      child: ExpansionTile(
        title: Text(question),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.deepOrange.withOpacity(0.05),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}
