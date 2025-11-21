import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/merchant_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<MerchantProvider>().fetchMerchants(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final merchant = context.watch<MerchantProvider>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakong POS'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).pushNamed('/profile'),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, size: 20, color: const Color(0xFFE53935)),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildUserAvatar(auth),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?['name'] ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.user?['email'] ?? 'email@example.com',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // KHQR Button
          Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           child: SizedBox(
             width: double.infinity,
             height: 56,
             child: ElevatedButton.icon(
               icon: const Icon(Icons.qr_code_2),
               label: const Text('KHQR'),
               onPressed: () {
                 Navigator.of(context).pushNamed('/khqr-receive');
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFFE53935),
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(12),
                 ),
               ),
             ),
           ),
          ),
          // Merchant Accounts Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Accounts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Account'),
                    onPressed: () => Navigator.of(context).pushNamed('/add-merchant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Merchants List
          Expanded(
            child: merchant.isLoading
                ? const Center(child: CircularProgressIndicator())
                : merchant.merchants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_center, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No accounts yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pushNamed('/add-merchant'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create First Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: 8,
                        ),
                        itemCount: merchant.merchants.length,
                        itemBuilder: (context, index) {
                          final m = merchant.merchants[index];
                          return MerchantCard(
                            merchant: m,
                            onTap: () {
                              merchant.selectMerchant(m);
                              Navigator.of(context)
                                  .pushNamed('/merchant-detail', arguments: m);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(AuthProvider auth) {
    final profile = auth.user?['profile'] as Map<String, dynamic>? ?? {};
    final avatarPath = profile['avatar'];

    // If there's an uploaded avatar, display it
    if (avatarPath != null && avatarPath.toString().isNotEmpty) {
      const baseUrl = 'http://10.0.2.2:8000';
      final imageUrl = '$baseUrl/storage/$avatarPath';
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (error, stackTrace) {},
        child: null,
      );
    }

    // Default: show initials
    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFE53935),
      child: Text(
        (auth.user?['name'] ?? 'U')[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class MerchantCard extends StatelessWidget {
  final dynamic merchant;
  final VoidCallback onTap;

  const MerchantCard({
    super.key,
    required this.merchant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBakongToken = merchant['bakong_token'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      merchant['merchant_name'] ?? 'Unnamed',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasBakongToken ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasBakongToken ? Icons.check_circle : Icons.warning_amber,
                          size: 14,
                          color: hasBakongToken ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasBakongToken ? 'Active' : 'Setup',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasBakongToken ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Account ID & Location
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Account',
                      merchant['account_id'] ?? 'N/A',
                      Icons.numbers,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Location',
                      merchant['location'] ?? 'N/A',
                      Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Arrow
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
