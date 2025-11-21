import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/merchant_provider.dart';
import '../providers/auth_provider.dart';

class AddMerchantScreen extends StatefulWidget {
  const AddMerchantScreen({super.key});

  @override
  State<AddMerchantScreen> createState() => _AddMerchantScreenState();
}

class _AddMerchantScreenState extends State<AddMerchantScreen> {
  final _accountIdController = TextEditingController();
  final _merchantNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bakongTokenController = TextEditingController();
  final _telegramChatIdController = TextEditingController();
  final _telegramBotTokenController = TextEditingController();
  
  dynamic _editingMerchant;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editingMerchant == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        _editingMerchant = args;
        _accountIdController.text = _editingMerchant['account_id'] ?? '';
        _merchantNameController.text = _editingMerchant['merchant_name'] ?? '';
        _locationController.text = _editingMerchant['location'] ?? '';
        _bakongTokenController.text = _editingMerchant['bakong_token'] ?? '';
        _telegramChatIdController.text = _editingMerchant['telegram_chat_id'] ?? '';
        _telegramBotTokenController.text = _editingMerchant['telegram_bot_token'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _accountIdController.dispose();
    _merchantNameController.dispose();
    _locationController.dispose();
    _bakongTokenController.dispose();
    _telegramChatIdController.dispose();
    _telegramBotTokenController.dispose();
    super.dispose();
  }

  void _handleAdd() async {
    if (_merchantNameController.text.isEmpty ||
        _accountIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    final merchantProvider = context.read<MerchantProvider>();
    final merchantData = {
      'account_id': _accountIdController.text.trim(),
      'merchant_name': _merchantNameController.text.trim(),
      'location': _locationController.text.trim(),
      'bakong_token': _bakongTokenController.text.trim(),
      'telegram_chat_id': _telegramChatIdController.text.trim(),
      'telegram_bot_token': _telegramBotTokenController.text.trim(),
    };

    bool success = false;
    String successMessage = '';

    if (_editingMerchant != null) {
      // Update existing merchant
      success = await merchantProvider.updateMerchant(_editingMerchant['id'], merchantData);
      successMessage = 'Merchant updated successfully';
    } else {
      // Create new merchant
      final userId = context.read<AuthProvider>().user?['id'] as int?;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }
      success = await merchantProvider.createMerchant(merchantData, userId);
      successMessage = 'Merchant added successfully';
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            merchantProvider.error ?? 'Failed to save merchant',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingMerchant != null ? 'Edit Account' : 'New Account'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _accountIdController,
              decoration: InputDecoration(
                labelText: 'Account ID *',
                hintText: 'Enter account ID',
                prefixIcon: const Icon(Icons.account_box_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _merchantNameController,
              decoration: InputDecoration(
                labelText: 'Merchant Name *',
                hintText: 'Enter merchant name',
                prefixIcon: const Icon(Icons.store_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Enter location',
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bakongTokenController,
              decoration: InputDecoration(
                labelText: 'Bakong Token',
                hintText: 'Enter Bakong token',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telegramChatIdController,
              decoration: InputDecoration(
                labelText: 'Telegram Chat ID',
                hintText: 'Enter chat ID',
                prefixIcon: const Icon(Icons.chat_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telegramBotTokenController,
              decoration: InputDecoration(
                labelText: 'Telegram Bot Token',
                hintText: 'Enter bot token',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 28),
            Consumer<MerchantProvider>(
              builder: (context, merchantProvider, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: merchantProvider.isLoading ? null : _handleAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: merchantProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _editingMerchant != null ? 'Update Account' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
}
