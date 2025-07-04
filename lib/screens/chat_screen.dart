import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Stream<List<Map<String, dynamic>>>? _messagesStream;
  String? _currentUserId;
  String? _publicChannelId;
  bool _isLoading = false;
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id;
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() => _isLoading = true);
      _publicChannelId = await _chatService.getOrCreatePublicChannel();
      
      if (_publicChannelId != null) {
        setState(() {
          _messagesStream = _chatService.getMessagesStream(_publicChannelId!);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      debugPrint('Channel initialization error: $e');
      _showErrorSnackbar('Failed to initialize chat channel');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom({int durationMillis = 300}) {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: durationMillis),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null || _publicChannelId == null) return;

    setState(() => _isLoading = true);
    try {
      final success = await _chatService.sendTextMessage(
        senderId: _currentUserId!,
        channelId: _publicChannelId!,
        content: text,
      );
      
      if (success) {
        _messageController.clear();
        _scrollToBottom();
      } else {
        _showErrorSnackbar('Failed to send message');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to send message: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAndSendFile(File file, String fileType) async {
    if (_currentUserId == null || _publicChannelId == null) return;

    setState(() => _isLoading = true);
    try {
      final success = await _chatService.uploadAndSendFile(
        senderId: _currentUserId!,
        channelId: _publicChannelId!,
        file: file,
        fileType: fileType,
      );
      
      if (success) {
        _scrollToBottom();
      } else {
        _showErrorSnackbar('Failed to send file');
      }
    } catch (e) {
      debugPrint('File upload error: $e');
      _showErrorSnackbar('Failed to send file');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_audioPlayer.playing) await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Audio play error: $e");
      _showErrorSnackbar('Could not play audio');
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    try {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint("Recording start error: $e");
      _showErrorSnackbar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null && mounted) {
        await _uploadAndSendFile(File(path), 'audio');
      }
    } catch (e) {
      debugPrint("Recording stop error: $e");
      _showErrorSnackbar('Failed to stop recording');
    } finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null && mounted) {
        await _uploadAndSendFile(File(pickedFile.path), 'image');
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
      _showErrorSnackbar('Failed to pick image');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null && mounted) {
        await _uploadAndSendFile(File(result.files.single.path!), 'file');
      }
    } catch (e) {
      debugPrint("File pick error: $e");
      _showErrorSnackbar('Failed to pick file');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Chat'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _initializeChat,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: _isLoading ? null : () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message['sender_id'] == _currentUserId;
                    return MessageBubble(
                      message: message,
                      isMine: isMine,
                      onPlayAudio: _playAudio,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_isRecording) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic, 
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recording audio...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: theme.colorScheme.primary,
                    tooltip: 'Attach',
                    onPressed: _isLoading || _isRecording
                        ? null
                        : () => _showAttachmentMenu(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _isRecording 
                          ? 'Recording audio...' 
                          : 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode 
                          ? const Color(0xFF2C2C2C) 
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 12,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _messageController,
                        builder: (context, value, child) {
                          if (_isLoading || _isRecording || value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: Icon(
                              Icons.send,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: _sendTextMessage,
                          );
                        },
                      ),
                    ),
                    enabled: !_isRecording,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isRecording 
                        ? theme.colorScheme.error.withOpacity(0.2) 
                        : theme.colorScheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording 
                          ? theme.colorScheme.error 
                          : theme.colorScheme.secondary,
                    ),
                    tooltip: _isRecording ? 'Stop recording' : 'Start recording',
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_isRecording) {
                              _stopRecording();
                            } else {
                              _startRecording();
                            }
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Attachments',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    ctx,
                    icon: Icons.photo_library,
                    color: Colors.purple,
                    label: 'Gallery',
                    onTap: _pickImage,
                  ),
                  _buildAttachmentOption(
                    ctx,
                    icon: Icons.camera_alt,
                    color: Colors.red,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final pickedFile = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                      );
                      if (pickedFile != null && mounted) {
                        await _uploadAndSendFile(File(pickedFile.path), 'image');
                      }
                    },
                  ),
                  _buildAttachmentOption(
                    ctx,
                    icon: Icons.insert_drive_file,
                    color: Colors.blue,
                    label: 'Document',
                    onTap: _pickFile,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}