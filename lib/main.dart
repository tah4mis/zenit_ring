import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF3B82F6),
        ),
      ),
      home: const NFCHomePage(),
    );
  }
}

class CardInfo {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cardType;
  final String bankName;

  CardInfo({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cardType,
    required this.bankName,
  });
}

class Transaction {
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final bool isExpense;
  final String category;

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.isExpense,
    required this.category,
  });
}

class NFCHomePage extends StatefulWidget {
  const NFCHomePage({super.key});

  @override
  State<NFCHomePage> createState() => _NFCHomePageState();
}

class _NFCHomePageState extends State<NFCHomePage> {
  String _status = 'NFC kartını bekliyor...';
  String? _tagData;
  double _balance = 0.0;
  final List<Transaction> _transactions = [];
  final List<CardInfo> _cards = [];
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Diğer';
  int _selectedIndex = 0;

  // Kart bilgileri için controller'lar
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _bankNameController = TextEditingController();
  String _selectedCardType = 'Kredi Kartı';

  final List<String> _categories = [
    'Market',
    'Ulaşım',
    'Faturalar',
    'Eğlence',
    'Sağlık',
    'Diğer'
  ];

  final List<String> _cardTypes = [
    'Kredi Kartı',
    'Banka Kartı',
    'Sanal Kart',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _addCard() {
    if (_cardNumberController.text.isEmpty ||
        _cardHolderController.text.isEmpty ||
        _expiryDateController.text.isEmpty ||
        _bankNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm kart bilgilerini doldurun')),
      );
      return;
    }

    setState(() {
      final card = CardInfo(
        id: DateTime.now().toString(),
        cardNumber: _cardNumberController.text,
        cardHolder: _cardHolderController.text,
        expiryDate: _expiryDateController.text,
        cardType: _selectedCardType,
        bankName: _bankNameController.text,
      );
      _cards.add(card);
      _cardNumberController.clear();
      _cardHolderController.clear();
      _expiryDateController.clear();
      _bankNameController.clear();
    });
  }

  void _showAddCardDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Yeni Kart Ekle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCardType,
                decoration: const InputDecoration(
                  labelText: 'Kart Tipi',
                  border: OutlineInputBorder(),
                ),
                items: _cardTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCardType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Kart Numarası',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Kart Sahibi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _expiryDateController,
                decoration: const InputDecoration(
                  labelText: 'Son Kullanma Tarihi (AA/YY)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Banka Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addCard();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Kartı Kaydet',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kartlarım',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _showAddCardDialog,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF1E3A8A),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cards.isEmpty)
              const Center(
                child: Text(
                  'Henüz kart eklenmemiş',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        card.cardType == 'Kredi Kartı'
                            ? Icons.credit_card
                            : Icons.account_balance,
                        color: const Color(0xFF1E3A8A),
                      ),
                      title: Text(
                        '${card.bankName} - ${card.cardType}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '**** **** **** ${card.cardNumber.substring(card.cardNumber.length - 4)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.nfc),
                        onPressed: () {
                          // NFC yazma işlemi burada yapılacak
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kart bilgileri yüzüğe yazılıyor...'),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _addTransaction(bool isExpense) {
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text;

    if (amount == null || amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir miktar ve açıklama girin')),
      );
      return;
    }

    setState(() {
      final transaction = Transaction(
        id: DateTime.now().toString(),
        amount: amount,
        description: description,
        date: DateTime.now(),
        isExpense: isExpense,
        category: _selectedCategory,
      );
      _transactions.add(transaction);
      _balance += isExpense ? -amount : amount;
      _amountController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> _readNFCTag() async {
    if (kIsWeb) {
      setState(() {
        _status = 'Web tarayıcıda NFC özelliği kullanılamaz. Lütfen mobil uygulamayı kullanın.';
      });
      return;
    }

    try {
      setState(() {
        _status = 'NFC kartı okunuyor...';
      });

      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        setState(() {
          _status = 'NFC kullanılamıyor: $availability';
        });
        return;
      }

      var tag = await FlutterNfcKit.poll();
      setState(() {
        _tagData = tag.id;
        _status = 'Kart okundu! ID: ${tag.id}';
      });
    } catch (e) {
      setState(() {
        _status = 'Hata: $e';
      });
    }
  }

  Future<void> _writeNFCTag() async {
    if (kIsWeb) {
      setState(() {
        _status = 'Web tarayıcıda NFC özelliği kullanılamaz. Lütfen mobil uygulamayı kullanın.';
      });
      return;
    }

    if (_tagData == null) {
      setState(() {
        _status = 'Önce bir kart okuyun!';
      });
      return;
    }

    try {
      setState(() {
        _status = 'NFC kartına yazılıyor...';
      });

      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        setState(() {
          _status = 'NFC kullanılamıyor: $availability';
        });
        return;
      }

      var tag = await FlutterNfcKit.poll();
      setState(() {
        _status = 'Karta yazma başarılı!';
      });
    } catch (e) {
      setState(() {
        _status = 'Yazma hatası: $e';
      });
    }
  }

  Widget _buildRingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Zenit',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.nfc, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Aktif',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₺${_balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(Icons.add, 'Para Ekle', () {
                  _showTransactionDialog(false);
                }),
                _buildQuickAction(Icons.remove, 'Harcama', () {
                  _showTransactionDialog(true);
                }),
                _buildQuickAction(Icons.history, 'Geçmiş', () {
                  setState(() => _selectedIndex = 1);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDialog(bool isExpense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpense ? 'Yeni Harcama' : 'Para Ekle',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Miktar',
                  border: OutlineInputBorder(),
                  prefixText: '₺',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addTransaction(isExpense);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpense ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isExpense ? 'Harcama Ekle' : 'Para Ekle',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Text(
          'Henüz işlem bulunmuyor',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[_transactions.length - 1 - index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: transaction.isExpense
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              child: Icon(
                transaction.isExpense ? Icons.remove : Icons.add,
                color: transaction.isExpense ? Colors.red : Colors.green,
              ),
            ),
            title: Text(
              transaction.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.category),
                Text(
                  '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Text(
              '${transaction.isExpense ? '-' : '+'}₺${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: transaction.isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNFCSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.nfc, size: 24, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'NFC Yüzük İşlemleri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.ring_volume,
                    size: 48,
                    color: Color(0xFF1E3A8A),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Yüzüğünüzü cihaza yaklaştırın',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_tagData != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Son Okunan Yüzük',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tagData!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              onPressed: _readNFCTag,
              icon: const Icon(Icons.nfc),
              label: const Text('Yüzüğü Oku'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _writeNFCTag,
              icon: const Icon(Icons.nfc),
              label: const Text('Yüzüğe Yaz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zenit'),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Ana Sayfa
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRingCard(),
                  const SizedBox(height: 20),
                  _buildCardsSection(),
                  const SizedBox(height: 20),
                  const Text(
                    'Son İşlemler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTransactionList(),
                ],
              ),
            ),
          ),
          // İşlem Geçmişi
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRingCard(),
                  const SizedBox(height: 20),
                  const Text(
                    'Tüm İşlemler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTransactionList(),
                ],
              ),
            ),
          ),
          // NFC İşlemleri
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRingCard(),
                  const SizedBox(height: 20),
                  _buildNFCSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'İşlemler',
          ),
          NavigationDestination(
            icon: Icon(Icons.nfc_outlined),
            selectedIcon: Icon(Icons.nfc),
            label: 'Yüzük',
          ),
        ],
      ),
    );
  }
}
