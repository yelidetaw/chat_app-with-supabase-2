import 'package:flutter/material.dart';
import 'package:chat_app/services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  
  const UserProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _authService.getUserProfile(widget.userId);
      
      if (mounted && profile != null) {
        setState(() => _userProfile = profile);
      } else if (mounted) {
        setState(() => _errorMessage = 'User profile not found');
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load user profile');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile != null 
            ? '${_userProfile!['username'] ?? 'User'} Profile'
            : 'User Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _userProfile != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // User avatar
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            backgroundImage: _userProfile!['avatar_url'] != null
                                ? NetworkImage(_userProfile!['avatar_url']) as ImageProvider
                                : null,
                            child: _userProfile!['avatar_url'] == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Username
                          Text(
                            _userProfile!['username'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // User info card
                          Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'User Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  
                                  // User ID
                                  _buildInfoRow(
                                    icon: Icons.fingerprint,
                                    title: 'User ID',
                                    subtitle: _truncateUserId(widget.userId),
                                  ),
                                  
                                  // Email (if available)
                                  if (_userProfile!['email'] != null)
                                    _buildInfoRow(
                                      icon: Icons.email,
                                      title: 'Email',
                                      subtitle: _userProfile!['email'],
                                    ),
                                    
                                  // Created at date (if available)
                                  if (_userProfile!['created_at'] != null)
                                    _buildInfoRow(
                                      icon: Icons.calendar_today,
                                      title: 'Joined',
                                      subtitle: _formatDate(_userProfile!['created_at']),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Action buttons
                          OutlinedButton.icon(
                            icon: const Icon(Icons.message),
                            label: const Text('Send Message'),
                            onPressed: () {
                              // In the future, can implement direct messaging
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Direct messaging coming soon!'),
                                ),
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text('User not found'),
                    ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _truncateUserId(String userId) {
    if (userId.length > 12) {
      return '${userId.substring(0, 6)}...${userId.substring(userId.length - 6)}';
    }
    return userId;
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays < 1) {
        return 'Today';
      } else if (difference.inDays < 2) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else {
        return '${(difference.inDays / 365).floor()} years ago';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
}