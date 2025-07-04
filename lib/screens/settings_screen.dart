import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/services/theme_service.dart';
import 'package:chat_app/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _soundsEnabled = true;
  String _language = 'English';
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme section
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: Text(isDarkMode ? 'On' : 'Off'),
            value: isDarkMode,
            onChanged: (value) => themeService.toggleTheme(),
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(),
          
          // Notifications section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive alerts for new messages'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _showSnackbar('Notification settings updated');
            },
            secondary: Icon(
              _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SwitchListTile(
            title: const Text('Message Sounds'),
            subtitle: const Text('Play sounds for new messages'),
            value: _soundsEnabled,
            onChanged: (value) {
              setState(() => _soundsEnabled = value);
              _showSnackbar('Sound settings updated');
            },
            secondary: Icon(
              _soundsEnabled ? Icons.volume_up : Icons.volume_off,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(),
          
          // Language section
          _buildSectionHeader('Language'),
          ListTile(
            title: const Text('App Language'),
            subtitle: Text(_language),
            leading: Icon(
              Icons.language,
              color: Theme.of(context).colorScheme.primary,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(),
          ),
          const Divider(),
          
          // Privacy section
          _buildSectionHeader('Privacy & Security'),
          ListTile(
            title: const Text('Clear Chat History'),
            subtitle: const Text('Delete all your messages'),
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => _showClearHistoryDialog(),
          ),
          const Divider(),
          
          // Account section
          _buildSectionHeader('Account'),
          ListTile(
            title: const Text('Edit Profile'),
            subtitle: Text(_authService.currentUser?.email ?? 'Not signed in'),
            leading: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => Navigator.of(context).pushNamed('/profile'),
          ),
          ListTile(
            title: const Text('Sign Out'),
            subtitle: const Text('Log out from your account'),
            leading: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () => _showSignOutDialog(),
          ),
          
          // About section
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          // Extra padding at bottom
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('Spanish'),
            _buildLanguageOption('French'),
            _buildLanguageOption('German'),
            _buildLanguageOption('Chinese'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _language == language 
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        setState(() => _language = language);
        Navigator.pop(context);
        _showSnackbar('Language changed to $language');
      },
    );
  }
  
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all your chat history? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear chat history functionality
              _showSnackbar('Chat history cleared');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', 
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}