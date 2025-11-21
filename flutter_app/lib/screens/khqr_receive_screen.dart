import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/merchant_provider.dart';
import '../services/api_service.dart';

class KhqrReceiveScreen extends StatefulWidget {
  const KhqrReceiveScreen({super.key});

  @override
  State<KhqrReceiveScreen> createState() => _KhqrReceiveScreenState();
}

class _KhqrReceiveScreenState extends State<KhqrReceiveScreen> {
  late String _selectedCurrency;
  late String _amount;
  final _amountController = TextEditingController();
  String? _qrData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = 'KHR';
    _amount = '0';
    _amountController.text = _amount;
    _generateQRCode();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.post(
        '/bakong/generate-qr',
        {
          'amount': _amount,
          'currency': _selectedCurrency,
        },
      );

      setState(() {
        _qrData = response['qr_string'] ?? response['qr_data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating QR: $e')),
        );
      }
    }
  }

  void _setAmount() {
    final newAmount = _amountController.text.trim();
    if (newAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    setState(() {
      _amount = newAmount;
    });
    Navigator.pop(context);
    _generateQRCode();
  }

  void _changeCurrency(String currency) {
    setState(() {
      _selectedCurrency = currency;
    });
    _generateQRCode();
  }

  void _shareQRCode() {
    if (_qrData == null) return;
    
    final merchant = context.read<MerchantProvider>();
    String merchantName = 'User';
    if (merchant.selectedMerchant != null) {
      merchantName = merchant.selectedMerchant!['merchant_name'] ?? 'User';
    } else if (merchant.merchants.isNotEmpty) {
      merchantName = merchant.merchants[0]['merchant_name'] ?? 'User';
    }
    
    Share.share(
      'Receive money via KHQR\nMerchant: $merchantName\nAmount: $_amount $_selectedCurrency\nQR Data: $_qrData',
      subject: 'KHQR Payment Request - $merchantName',
    );
  }

  void _printQRCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final merchant = context.watch<MerchantProvider>();
    
    // Get merchant name from selected merchant or first merchant
    String merchantName = 'User';
    if (merchant.selectedMerchant != null) {
      merchantName = merchant.selectedMerchant!['merchant_name'] ?? 'User';
    } else if (merchant.merchants.isNotEmpty) {
      merchantName = merchant.merchants[0]['merchant_name'] ?? 'User';
    } else {
      merchantName = auth.user?['name'] ?? 'User';
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Receive money',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Currency Toggle
              Row(
                children: [
                  Expanded(
                    child: _buildCurrencyButton(
                      'Riel currency',
                      'KHR',
                      _selectedCurrency == 'KHR',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCurrencyButton(
                      'Usd currency',
                      'USD',
                      _selectedCurrency == 'USD',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // KHQR Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Red Header
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'KHQR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Merchant Name
                          Text(
                            merchantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Amount
                          Text(
                            _amount,
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Divider
                          Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 24),
                          // QR Code
                          _buildQRCodeWidget(),
                          const SizedBox(height: 24),
                          // Print and Share Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Print',
                                  Icons.print_outlined,
                                  _printQRCode,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  'Share',
                                  Icons.share_outlined,
                                  _shareQRCode,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Set Amount Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showSetAmountDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Set amount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeWidget() {
    if (_isLoading) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
              const SizedBox(height: 8),
              Text(
                'Error generating QR',
                style: TextStyle(color: Colors.red.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_qrData == null || _qrData!.isEmpty) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No QR data'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: QrImageView(
        data: _qrData!,
        size: 200,
        backgroundColor: Colors.white,
        errorStateBuilder: (cxt, err) {
          return Center(
            child: Text('Error: $err'),
          );
        },
      ),
    );
  }

  Widget _buildCurrencyButton(String label, String code, bool isSelected) {
    return GestureDetector(
      onTap: () => _changeCurrency(code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFFE53935))
              : Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  code == 'KHR' ? Icons.currency_exchange : Icons.attach_money,
                  color: isSelected ? const Color(0xFFE53935) : Colors.grey[600],
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[700], size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetAmountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Amount'),
        content: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.attach_money),
            suffixText: _selectedCurrency,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _setAmount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}