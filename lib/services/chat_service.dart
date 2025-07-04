import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:chat_app/main.dart';

class ChatService {
  final SupabaseClient _supabase = supabase;
  final _uuid = const Uuid();
  
  // Get or create the public channel
  Future<String?> getOrCreatePublicChannel() async {
    try {
      // Try to fetch existing channel
      final response = await _supabase
          .from('channels')
          .select('id')
          .eq('name', publicChannelName)
          .maybeSingle();

      if (response != null && response.isNotEmpty) {
        return response['id'].toString();
      }

      // Create new channel if none exists
      final insertResponse = await _supabase
          .from('channels')
          .insert({'name': publicChannelName})
          .select('id')
          .single();

      return insertResponse['id'].toString();
    } catch (e) {
      debugPrint('Error in getOrCreatePublicChannel: $e');
      return null;
    }
  }

  // Get messages stream for a channel
  Stream<List<Map<String, dynamic>>> getMessagesStream(String channelId) {
    return _supabase
        .from(messagesTable)
        .stream(primaryKey: ['id'])
        .eq('receiver_id', channelId)
        .order('created_at', ascending: true)
        .map((maps) => maps.toList());
  }

  // Send a text message
  Future<bool> sendTextMessage({
    required String senderId,
    required String channelId,
    required String content,
  }) async {
    try {
      await _supabase.from(messagesTable).insert({
        'sender_id': senderId,
        'receiver_id': channelId,
        'content': content,
        'file_type': 'text',
        'is_sent': true,
        'is_read': false,
      });
      return true;
    } catch (e) {
      debugPrint('Error sending text message: $e');
      return false;
    }
  }

  // Upload and send a file message
  Future<bool> uploadAndSendFile({
    required String senderId,
    required String channelId,
    required File file,
    required String fileType,
  }) async {
    try {
      final fileExtension = file.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExtension';
      final filePath = '$senderId/$fileName';

      // Upload file to Supabase storage
      await _supabase.storage.from(chatFilesBucket).upload(filePath, file);
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from(chatFilesBucket)
          .getPublicUrl(filePath);

      // Send message with file attachment
      await _supabase.from(messagesTable).insert({
        'sender_id': senderId,
        'receiver_id': channelId,
        'file_url': publicUrl,
        'file_type': fileType,
        'file_metadata': {
          'file_name': file.path.split('/').last,
          'file_size': await file.length(),
        },
        'is_sent': true,
        'is_read': false,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error uploading and sending file: $e');
      return false;
    }
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead(String channelId) async {
    try {
      await _supabase
          .from(messagesTable)
          .update({'is_read': true})
          .eq('receiver_id', channelId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
}