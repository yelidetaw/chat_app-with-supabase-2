import 'package:flutter/material.dart';
import 'package:chat_app/utils/message_utils.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class FileAttachmentWidget extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final bool isDark;

  const FileAttachmentWidget({
    Key? key,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    this.isDark = false,
  }) : super(key: key);

  String _getFileTypeIcon() {
    final extension = fileUrl.split('.').last.toLowerCase();
    
    if (['pdf'].contains(extension)) {
      return 'document';
    } else if (['doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      return 'document';
    } else if (['xls', 'xlsx', 'csv'].contains(extension)) {
      return 'spreadsheet';
    } else if (['ppt', 'pptx'].contains(extension)) {
      return 'presentation';
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return 'archive';
    } else {
      return 'file';
    }
  }

  IconData _getIconData() {
    final fileType = _getFileTypeIcon();
    
    switch (fileType) {
      case 'document':
        return Icons.insert_drive_file;
      case 'spreadsheet':
        return Icons.table_chart;
      case 'presentation':
        return Icons.slideshow;
      case 'archive':
        return Icons.folder_zip;
      default:
        return Icons.attachment;
    }
  }

  Future<void> _openFile() async {
    if (await url_launcher.canLaunchUrl(Uri.parse(fileUrl))) {
      await url_launcher.launchUrl(
        Uri.parse(fileUrl),
        mode: url_launcher.LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark
        ? Colors.white.withOpacity(0.8)
        : Theme.of(context).primaryColor;
    final backgroundColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.grey.withOpacity(0.1);
        
    return GestureDetector(
      onTap: _openFile,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _getIconData(),
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    getFormattedFileSize(fileSize),
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: textColor.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}