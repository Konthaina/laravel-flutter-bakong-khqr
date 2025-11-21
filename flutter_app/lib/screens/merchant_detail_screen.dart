import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/merchant_provider.dart';

class MerchantDetailScreen extends StatefulWidget {
  final dynamic merchant;

  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  State<MerchantDetailScreen> createState() => _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends State<MerchantDetailScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  void _editMerchant() {
    Navigator.of(context).pushNamed(
      '/edit-merchant',
      arguments: widget.merchant,
    );
  }

  void _deleteMerchant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete this account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<MerchantProvider>()
                  .deleteMerchant(widget.merchant['id']);
              if (success && mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hasBakongToken = widget.merchant['bakong_token'] != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Edit',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                onTap: _editMerchant,
              ),
              PopupMenuItem(
                child: Row(
                  children: const [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: _deleteMerchant,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Merchant Card (Like Account Card in Banking App)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasBakongToken ? Colors.green.shade400 : Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hasBakongToken ? 'Active' : 'Setup Required',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.merchant['merchant_name'] ?? 'Unnamed Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Account ID: ${widget.merchant['account_id']}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.merchant['location'] != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Colors.white.withValues(alpha: 0.8), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          widget.merchant['location'],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Information Grid
            Text(
              'Account Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        _buildInfoCard(
          'Bakong Token',
          widget.merchant['bakong_token'] != null
              ? '${widget.merchant['bakong_token'].toString().substring(0, 10)}...'
              : 'Not set',
          Icons.vpn_key_outlined,
          widget.merchant['bakong_token'] != null ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          'Telegram Chat ID',
          widget.merchant['telegram_chat_id'] ?? 'Not set',
          Icons.chat_outlined,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          'Telegram Bot Token',
          widget.merchant['telegram_bot_token'] != null
              ? '${widget.merchant['telegram_bot_token'].toString().substring(0, 10)}...'
              : 'Not set',
          Icons.smart_toy_outlined,
          Colors.purple,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          'Created',
          _formatDate(widget.merchant['created_at']),
          Icons.calendar_today_outlined,
          Colors.grey,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          'Last Updated',
          _formatDate(widget.merchant['updated_at']),
          Icons.update_outlined,
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

class QRCodeWidget extends StatelessWidget {
  final String data;

  const QRCodeWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Scan with Bakong App',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        _buildQrCode(data),
      ],
    );
  }

  Widget _buildQrCode(String qrData) {
    try {
      return _QrImageWidget(data: qrData);
    } catch (e) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('QR: ${qrData.substring(0, 20)}...'),
        ),
      );
    }
  }
}

class _QrImageWidget extends StatelessWidget {
  final String data;

  const _QrImageWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: QrImageView(
        data: data,
        size: 250,
        backgroundColor: Colors.white,
      ),
    );
  }
}
