import 'package:flutter/material.dart';
import 'package:chat_app/utils/message_utils.dart';
import 'package:chat_app/widgets/audio_player_widget.dart';
import 'package:chat_app/widgets/file_attachment_widget.dart';
import 'package:chat_app/screens/user_profile_screen.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMine;
  final Function(String) onPlayAudio;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMine,
    required this.onPlayAudio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = message['content'] as String?;
    final fileType = message['file_type'] as String? ?? 'text';
    final fileUrl = message['file_url'] as String?;
    final fileMetadata = message['file_metadata'] as Map<String, dynamic>?;
    
    DateTime? timestamp;
    try {
      if (message['created_at'] != null) {
        timestamp = DateTime.parse(message['created_at'] as String);
      }
    } catch (e) {
      timestamp = DateTime.now();
    }
    
    final formattedTime = timestamp != null 
        ? formatTimestamp(timestamp) 
        : 'Just now';
        
    final isSent = message['is_sent'] as bool? ?? false;
    final isRead = message['is_read'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMine ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isMine ? 12 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine)
                GestureDetector(
                  onTap: () {
                    final senderId = message['sender_id']?.toString();
                    if (senderId != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: senderId),
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'User ${message['sender_id']?.toString().substring(0, 6) ?? 'Unknown'}',
                        style: TextStyle(
                          color: isMine ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                
              if (content != null && content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                
              if (fileUrl != null) ...[
                if (fileType == 'image' && isImageFile(fileUrl))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fileUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                  
                if (fileType == 'audio' && isAudioFile(fileUrl))
                  AudioPlayerWidget(
                    audioUrl: fileUrl,
                    onPlay: () => onPlayAudio(fileUrl),
                    isDark: isMine,
                  ),
                  
                if (fileType == 'file' || 
                    (!isImageFile(fileUrl) && !isAudioFile(fileUrl)))
                  FileAttachmentWidget(
                    fileUrl: fileUrl,
                    fileName: fileMetadata?['file_name'] ?? 'File',
                    fileSize: fileMetadata?['file_size'] ?? 0,
                    isDark: isMine,
                  ),
              ],
              
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMine ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 12,
                        color: isRead 
                            ? (isMine ? Colors.white70 : Colors.blue) 
                            : (isMine ? Colors.white70 : Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}