import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  String? _selectedGender;
  DateTime? _selectedBirthdate;
  File? _selectedImage;
  
  bool _isEditing = false;
  bool _isUploadingImage = false;
  
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final profile = auth.user?['profile'] as Map<String, dynamic>? ?? {};
    
    _nameController = TextEditingController(text: auth.user?['name'] ?? '');
    _emailController = TextEditingController(text: auth.user?['email'] ?? '');
    _phoneController = TextEditingController(text: profile['phone']?.toString() ?? '');
    _addressController = TextEditingController(text: profile['address']?.toString() ?? '');
    
    // Set gender and birthdate
    final genderValue = profile['gender'];
    if (genderValue != null && genderValue.toString().isNotEmpty) {
      _selectedGender = genderValue.toString();
    }
    
    final birthdateValue = profile['birthdate'];
    if (birthdateValue != null && birthdateValue.toString().isNotEmpty) {
      try {
        _selectedBirthdate = DateTime.parse(birthdateValue.toString());
      } catch (e) {
        _selectedBirthdate = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
    if (!_isEditing) {
      // Reset to original values if cancelled
      final auth = context.read<AuthProvider>();
      final profile = auth.user?['profile'] as Map<String, dynamic>? ?? {};
      _nameController.text = auth.user?['name'] ?? '';
      _emailController.text = auth.user?['email'] ?? '';
      _phoneController.text = profile['phone']?.toString() ?? '';
      _addressController.text = profile['address']?.toString() ?? '';
      
      final genderValue = profile['gender'];
      _selectedGender = (genderValue != null && genderValue.toString().isNotEmpty)
          ? genderValue.toString()
          : null;
      
      final birthdateValue = profile['birthdate'];
      if (birthdateValue != null && birthdateValue.toString().isNotEmpty) {
        try {
          _selectedBirthdate = DateTime.parse(birthdateValue.toString());
        } catch (e) {
          _selectedBirthdate = null;
        }
      } else {
        _selectedBirthdate = null;
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your name')),
      );
      return;
    }

    final profileData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    // Add optional fields only if selected
    if (_selectedGender != null && _selectedGender!.isNotEmpty) {
      profileData['gender'] = _selectedGender!;
    }
    if (_selectedBirthdate != null) {
      profileData['birthdate'] = _formatDateForAPI(_selectedBirthdate!);
    }

    final success = await context.read<AuthProvider>().updateProfile(profileData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      setState(() {
        _isEditing = false;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().error ?? 'Failed to update profile',
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _uploadImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?['id'];
      final token = auth.token;

      if (userId == null) {
        throw Exception('User ID not found');
      }

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      const baseUrl = 'http://10.0.2.2:8000/api';
      final uploadUrl = Uri.parse('$baseUrl/users/$userId/profile');

      final request = http.MultipartRequest('POST', uploadUrl);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          _selectedImage!.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['user'] != null) {
          context.read<AuthProvider>().updateUserData(jsonResponse['user']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar uploaded successfully')),
        );
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        actions: [
          if (!_isEditing && !auth.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _toggleEdit,
                tooltip: 'Edit Profile',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: 20,
        ),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildAvatarImage(auth),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.camera_alt_outlined,
                                color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // User Name
            if (!_isEditing)
              Column(
                children: [
                  Text(
                    auth.user?['name'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            // Profile Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing)
                      Column(
                        children: [
                          _buildEditSection(),
                          const SizedBox(height: 32),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: authProvider.isLoading ? null : _saveProfile,
                                      icon: authProvider.isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.check_outlined),
                                      label: const Text('Save Changes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE53935),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: authProvider.isLoading ? null : _toggleEdit,
                                      icon: const Icon(Icons.close_outlined),
                                      label: const Text('Cancel'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey[600],
                                        side: BorderSide(color: Colors.grey[300]!),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      )
                    else
                      _buildViewSection(auth),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEditSection() {
    return Column(
      children: [
        _buildEditField('Full Name', _nameController, Icons.person_outline),
        const SizedBox(height: 16),
        _buildEditField('Email Address', _emailController, Icons.email_outlined, enabled: false),
        const SizedBox(height: 16),
        _buildEditField('Phone Number', _phoneController, Icons.phone_outlined),
        const SizedBox(height: 16),
        _buildEditField('Address', _addressController, Icons.location_on_outlined),
        const SizedBox(height: 16),
        _buildGenderDropdown(),
        const SizedBox(height: 16),
        _buildBirthdatePicker(),
      ],
    );
  }

  Widget _buildViewSection(AuthProvider auth) {
    final profile = auth.user?['profile'] as Map<String, dynamic>? ?? {};
    return Column(
      children: [
        _buildProfileItem('Email Address', auth.user?['email'], Icons.email_outlined),
        const Divider(height: 24),
        _buildProfileItem('Phone Number', profile['phone']?.toString() ?? 'Not set', Icons.phone_outlined),
        const Divider(height: 24),
        _buildProfileItem('Address', profile['address']?.toString() ?? 'Not set', Icons.location_on_outlined),
        const Divider(height: 24),
        _buildProfileItem('Gender', profile['gender']?.toString() ?? 'Not set', Icons.person_outline),
        const Divider(height: 24),
        _buildProfileItem(
          'Birthdate',
          profile['birthdate'] != null ? _formatDate(profile['birthdate']) : 'Not set',
          Icons.calendar_today_outlined,
        ),
        const Divider(height: 24),
        _buildProfileItem('Member Since', _formatDate(auth.user?['created_at']), Icons.verified_user_outlined),
      ],
    );
  }

  Widget _buildProfileItem(String label, String? value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE53935), size: 20),
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
                value ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(AuthProvider auth) {
    final profile = auth.user?['profile'] as Map<String, dynamic>? ?? {};
    final avatarPath = profile['avatar'];
    
    if (_selectedImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_selectedImage!),
      );
    }
    
    if (avatarPath != null && avatarPath.toString().isNotEmpty) {
      const baseUrl = 'http://10.0.2.2:8000';
      final imageUrl = '$baseUrl/storage/$avatarPath';
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (error, stackTrace) {},
        child: null,
      );
    }
    
    return CircleAvatar(
      radius: 60,
      backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.15),
      child: Text(
        (auth.user?['name'] ?? 'U')[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE53935),
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      items: [
        const DropdownMenuItem(value: null, child: Text('Select Gender')),
        const DropdownMenuItem(value: 'Male', child: Text('Male')),
        const DropdownMenuItem(value: 'Female', child: Text('Female')),
        const DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person_outline, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
      ),
    );
  }

  Widget _buildBirthdatePicker() {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedBirthdate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            _selectedBirthdate = pickedDate;
          });
        }
      },
      child: AbsorbPointer(
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Birthdate',
            hintText: 'YYYY-MM-DD',
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
            ),
          ),
          controller: TextEditingController(
            text: _selectedBirthdate != null
                ? _formatDateForAPI(_selectedBirthdate!)
                : '',
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
