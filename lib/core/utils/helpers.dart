import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';

class Helpers {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Normalizes any given timestamp to UTC for internal storage.
  /// If null, returns current UTC time.
  static DateTime toUtc(dynamic timestamp) {
    if (timestamp == null) return DateTime.now().toUtc();
    
    DateTime dt;
    if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      String str = timestamp.toString();
      // If backend returns "YYYY-MM-DD HH:MM:SS" without TZ, assume UTC
      if (!str.contains('Z') && !str.contains('+') && RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}').hasMatch(str)) {
        str = str.replaceFirst(' ', 'T') + 'Z';
      }
      dt = DateTime.tryParse(str) ?? DateTime.now();
    }
    return dt.toUtc();
  }

  /// Converts any given timestamp to Pakistan Standard Time (PKT, UTC+5) for display.
  static DateTime toPKT(dynamic timestamp) {
    DateTime utc = toUtc(timestamp);
    return utc.add(const Duration(hours: 5));
  }

  /// Formats date for Chat List and Chat Messages in PKT.
  static String formatTimestamp(dynamic timestamp) {
    final DateTime pktTime = toPKT(timestamp);
    final DateTime now = toPKT(DateTime.now());
    
    final bool isToday = pktTime.year == now.year && 
                       pktTime.month == now.month && 
                       pktTime.day == now.day;
    
    final bool isYesterday = pktTime.year == now.year && 
                           pktTime.month == now.month && 
                           pktTime.day == now.day - 1;

    if (isToday) {
      return DateFormat('hh:mm a').format(pktTime);
    } else if (isYesterday) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(pktTime)}';
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(pktTime);
    }
  }

  /// Short format for chat list
  static String formatShortTimestamp(dynamic timestamp) {
    final DateTime pktTime = toPKT(timestamp);
    final DateTime now = toPKT(DateTime.now());
    
    if (pktTime.year == now.year && pktTime.month == now.month && pktTime.day == now.day) {
      return DateFormat('hh:mm a').format(pktTime);
    } else if (pktTime.year == now.year && pktTime.month == now.month && pktTime.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yy').format(pktTime);
    }
  }

  /// Sanitizes a string to ensure it is well-formed UTF-16 for Flutter.
  /// Removes lone surrogates that cause "Invalid argument(s): string is not well-formed UTF-16".
  static String sanitizeString(String? text) {
    if (text == null || text.isEmpty) return '';

    try {
      final List<int> codeUnits = text.codeUnits;
      final List<int> sanitizedUnits = [];

      for (int i = 0; i < codeUnits.length; i++) {
        int unit = codeUnits[i];

        if (unit >= 0xD800 && unit <= 0xDBFF) {
          // High surrogate
          if (i + 1 < codeUnits.length) {
            int nextUnit = codeUnits[i + 1];
            if (nextUnit >= 0xDC00 && nextUnit <= 0xDFFF) {
              // Valid pair
              sanitizedUnits.add(unit);
              sanitizedUnits.add(nextUnit);
              i++;
              continue;
            }
          }
          // Lone high surrogate - skip
          continue;
        } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
          // Lone low surrogate - skip
          continue;
        }

        sanitizedUnits.add(unit);
      }

      return String.fromCharCodes(sanitizedUnits);
    } catch (e) {
      // Last resort fallback
      return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
    }
  }

  /// Deeply sanitizes a map or list to ensure all strings are well-formed.
  static dynamic sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      return sanitizeString(data);
    } else if (data is Map) {
      final Map<String, dynamic> sanitizedMap = {};
      data.forEach((key, value) {
        final String safeKey = key is String ? sanitizeString(key) : key.toString();
        sanitizedMap[safeKey] = sanitizeData(value);
      });
      return sanitizedMap;
    } else if (data is List) {
      return data.map((item) => sanitizeData(item)).toList();
    }
    return data;
  }

  /// Safely gets the first character of a string, handling surrogate pairs.
  static String getInitial(String? text) {
    if (text == null || text.trim().isEmpty) return '?';
    try {
      final sanitized = sanitizeString(text).trim();
      if (sanitized.isEmpty) return '?';
      return String.fromCharCode(sanitized.runes.first).toUpperCase();
    } catch (_) {
      return '?';
    }
  }

  static int? toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString());
  }

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String format24hCountdown(Duration duration) {
    if (duration.isNegative || duration.inSeconds == 0) return "expired";
    
    if (duration.inHours == 24 && duration.inMinutes.remainder(60) == 0 && duration.inSeconds.remainder(60) == 0) {
      return "24 hours";
    }
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    List<String> parts = [];
    if (hours > 0) {
      parts.add("${hours}h");
      parts.add("${minutes.toString().padLeft(2, '0')}m");
    } else if (minutes > 0) {
      parts.add("${minutes}m");
    }
    parts.add("${seconds.toString().padLeft(2, '0')}s");
    
    return parts.join(' ');
  }

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  /// Converts HTML string to WhatsApp-style plain text.
  static String htmlToPlainText(String? html) {
    if (html == null || html.isEmpty) return '';
    
    String text = html;
    
    // Replace <br> and <br/> with \n
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    
    // Replace <em> and </em> with _ (WhatsApp italic)
    text = text.replaceAll(RegExp(r'</?em>', caseSensitive: false), '_');
    
    // Replace <strong> and <b> with * (WhatsApp bold)
    text = text.replaceAll(RegExp(r'</?(strong|b)>', caseSensitive: false), '*');
    
    // For <a> tags, we want to extract the URL if the text doesn't contain it, 
    // but usually in these cases the text is the URL.
    // Let's just strip all remaining tags.
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities (like &amp; &lt; &gt; &quot; &#39;)
    text = text.replaceAll('&amp;', '&')
               .replaceAll('&lt;', '<')
               .replaceAll('&gt;', '>')
               .replaceAll('&quot;', '"')
               .replaceAll('&#39;', "'");
               
    return text.trim();
  }

  /// Checks for permissions and opens a file. If the file is remote, it downloads it first.
  static Future<void> openFile({
    required String urlOrPath,
    String? fileName,
    Function(double)? onProgress,
  }) async {
    if (urlOrPath.isEmpty) return;

    try {
      // 1. Handle Permissions (Required for Android)
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkInt();
        if (sdkInt != null && sdkInt >= 33) {
          // Android 13+ specific permissions
          await [
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ].request();
        } else {
          if (await Permission.storage.isDenied) {
            await Permission.storage.request();
          }
        }
      }

      String localPath = urlOrPath;

      // 2. Check if it's a remote URL
      if (urlOrPath.startsWith('http')) {
        final directory = await getApplicationDocumentsDirectory();
        final String name = fileName ?? urlOrPath.split('/').last;
        final String sanitizedName = name.replaceAll(RegExp(r'[^\w\s\.\-]'), '_');
        localPath = '${directory.path}/$sanitizedName';

        final File file = File(localPath);

        // 3. Download if not already exists
        if (!await file.exists()) {
          debugPrint('📥 Downloading file to: $localPath');
          final Dio dio = Dio();
          await dio.download(
            urlOrPath,
            localPath,
            onReceiveProgress: (received, total) {
              if (total != -1 && onProgress != null) {
                onProgress(received / total);
              }
            },
          );
        }
      }

      // 4. Open the file natively
      debugPrint('📂 Opening file: $localPath');
      final result = await OpenFilex.open(localPath);

      if (result.type != ResultType.done) {
        Fluttertoast.showToast(msg: result.message ?? "Could not open file");
      }
    } catch (e) {
      debugPrint('❌ Error opening file: $e');
      Fluttertoast.showToast(msg: "No application available to open this file.");
    }
  }

  /// Formats a message object into a WhatsApp-style preview string.
  static String getMessagePreview(Map<String, dynamic> contact) {
    final lastMessage = contact['last_message'];
    if (lastMessage is! Map) {
      // Check fallback fields in contact directly
      final text = contact['latest_message_text'] ?? contact['message'];
      if (text != null && text.toString().isNotEmpty) return text.toString();
      return '';
    }

    // 1. Determine Sender Name for Groups
    String prefix = '';
    final bool isGroup = contact['is_group_chat'] == true || 
                        contact['is_group'] == true || 
                        contact['type'] == 'group';
    
    if (isGroup) {
      final sender = lastMessage['sender_name'] ?? 
                     lastMessage['vendor_messaging_user']?['name'] ?? 
                     lastMessage['vendor_messaging_user']?['first_name'];
      if (sender != null && sender.toString().isNotEmpty) {
        prefix = '${sender.toString()}: ';
      }
    }

    // 2. Check for Deleted Status
    if (lastMessage['is_deleted'] == true || lastMessage['status'] == 'deleted') {
      return '${prefix}🚫 This message was deleted';
    }

    // 3. Identify Type
    String type = (lastMessage['message_type'] ?? lastMessage['type'] ?? '').toString().toLowerCase();
    
    // Deep extraction for type if it's "text" but might be media (e.g. from webhooks)
    if (type == 'text' || type.isEmpty) {
      final data = lastMessage['__data'];
      if (data is Map) {
        try {
          final msg = data['webhook_responses']?['incoming']?[0]?['changes']?[0]?['value']?['messages']?[0];
          final wType = msg?['type']?.toString().toLowerCase();
          if (wType != null) type = wType;
        } catch (_) {}
      }
    }

    // Fallback detection by content if type is still ambiguous
    if (type == 'text' || type.isEmpty) {
      final content = (lastMessage['message'] ?? lastMessage['text'] ?? '').toString().toLowerCase();
      if (content.endsWith('.webp')) type = 'sticker';
      else if (content.endsWith('.mp4') || content.endsWith('.mov')) type = 'video';
      else if (content.endsWith('.jpg') || content.endsWith('.png') || content.endsWith('.jpeg')) type = 'image';
      else if (content.startsWith('http')) {
        if (content.contains('/stickers/')) type = 'sticker';
        else if (content.contains('/images/')) type = 'image';
        else if (content.contains('/videos/')) type = 'video';
        else if (content.contains('/audio/')) type = 'voice';
      }
    }

    switch (type) {
      case 'image':
        return '${prefix}🖼️ Photo';
      case 'video':
        return '${prefix}🎥 Video';
      case 'voice':
      case 'ptt':
        return '${prefix} Voice message';
      case 'audio':
        return '${prefix} Voice message';
      case 'sticker':
        return '${prefix}😊 Sticker';
      case 'document':
      case 'file':
        final fileName = lastMessage['file_name'] ?? lastMessage['attachment_name'] ?? lastMessage['uploaded_media_file_name'];
        if (fileName != null && fileName.toString().isNotEmpty) {
          return '${prefix}📄 ${fileName.toString()}';
        }
        return '${prefix}📄 Document';
      case 'contact':
        return '${prefix}👤 Contact';
      case 'location':
        return '${prefix}📍 Location';
      case 'gif':
        return '${prefix}GIF';
      default:
        final text = lastMessage['message'] ??
                    lastMessage['text'] ??
                    lastMessage['body'] ??
                    lastMessage['message_body'] ??
                    lastMessage['caption'];
        
        if (text != null && text.toString().trim().isNotEmpty && text.toString() != 'Media') {
          return '${prefix}${htmlToPlainText(text.toString())}';
        } else if (lastMessage['wamid'] != null || type.isNotEmpty) {
          return '${prefix}📎 Media message';
        }
        return '';
    }
  }

  static Future<int?> _getAndroidSdkInt() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return null;
  }
}
