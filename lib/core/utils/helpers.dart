import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';

class Helpers {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Normalizes any given timestamp to UTC for internal storage.
  /// If null, returns current UTC time.
  static DateTime toUtc(dynamic timestamp) {
    if (timestamp == null) return DateTime.now().toUtc();

    if (timestamp is DateTime) {
      return timestamp.isUtc ? timestamp : timestamp.toUtc();
    }

    try {
      String str = timestamp.toString();
      // Optimization: common Laravel format "YYYY-MM-DD HH:MM:SS"
      if (str.length == 19 && str[10] == ' ') {
        str = '${str.substring(0, 10)}T${str.substring(11)}Z';
      } else if (!str.contains('Z') &&
          !str.contains('+') &&
          RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}').hasMatch(str)) {
        str = str.replaceFirst(' ', 'T') + 'Z';
      }
      return DateTime.tryParse(str)?.toUtc() ?? DateTime.now().toUtc();
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }

  /// Converts any given timestamp to Pakistan Standard Time (PKT, UTC+5) for display.
  static DateTime toPKT(dynamic timestamp) {
    DateTime utc = toUtc(timestamp);
    return utc.add(const Duration(hours: 5));
  }

  static final DateFormat _fullDateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  /// Formats date for Chat List and Chat Messages in PKT.
  static String formatTimestamp(dynamic timestamp) {
    final DateTime pktTime = toPKT(timestamp);
    final DateTime now = toPKT(DateTime.now());

    final bool isToday =
        pktTime.year == now.year &&
        pktTime.month == now.month &&
        pktTime.day == now.day;

    final bool isYesterday =
        pktTime.year == now.year &&
        pktTime.month == now.month &&
        pktTime.day == now.day - 1;

    if (isToday) {
      return _timeFormat.format(pktTime);
    } else if (isYesterday) {
      return 'Yesterday, ${_timeFormat.format(pktTime)}';
    } else {
      return _fullDateFormat.format(pktTime);
    }
  }

  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yy');

  /// Short format for chat list
  static String formatShortTimestamp(dynamic timestamp) {
    final DateTime pktTime = toPKT(timestamp);
    final DateTime now = toPKT(DateTime.now());

    if (pktTime.year == now.year &&
        pktTime.month == now.month &&
        pktTime.day == now.day) {
      return _timeFormat.format(pktTime);
    } else if (pktTime.year == now.year &&
        pktTime.month == now.month &&
        pktTime.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return _shortDateFormat.format(pktTime);
    }
  }

  /// Sanitizes a string to ensure it is well-formed UTF-16 for Flutter.
  /// Optimized to avoid processing if the string is already well-formed.
  static String sanitizeString(String? text) {
    if (text == null || text.isEmpty) return '';

    // Optimization: Check if string has any potentially problematic surrogates first
    bool hasSurrogates = false;
    for (int i = 0; i < text.length; i++) {
      int unit = text.codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDFFF) {
        hasSurrogates = true;
        break;
      }
    }

    if (!hasSurrogates) return text;

    try {
      final List<int> codeUnits = text.codeUnits;
      final List<int> sanitizedUnits = [];
      // sanitizedUnits.reserve(codeUnits.length); // REMOVED: reserve is not a Dart method

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
      return text.replaceAll(RegExp(r'[\uD800-\uDFFF]'), '');
    }
  }

  /// Deeply sanitizes a map or list to ensure all strings are well-formed.
  /// For performance, use sanitizeDataAsync for large datasets.
  static dynamic sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      return sanitizeString(data);
    } else if (data is Map) {
      // Use Map.from for faster iteration if it's already a Map<String, dynamic>
      final Map<String, dynamic> sanitizedMap = {};
      data.forEach((key, value) {
        final String safeKey = key is String
            ? sanitizeString(key)
            : key.toString();
        sanitizedMap[safeKey] = sanitizeData(value);
      });
      return sanitizedMap;
    } else if (data is List) {
      return data.map((item) => sanitizeData(item)).toList();
    }
    return data;
  }

  /// Performs heavy data sanitization in a background isolate to keep UI smooth.
  static Future<dynamic> sanitizeDataAsync(dynamic data) async {
    if (data == null) return null;
    if (data is! Map && data is! List) return sanitizeData(data);

    // Only use compute for reasonably sized data to avoid isolate overhead
    // A rough heuristic: if it's a list with > 10 items or a map
    return await compute(_sanitizeDataIsolate, data);
  }

  static dynamic _sanitizeDataIsolate(dynamic data) {
    return sanitizeData(data);
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

  static double? toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString());
  }

  /// Safely extracts the __data map from a message object, handling JSON strings.
  static Map<String, dynamic> getMessageData(dynamic message) {
    if (message is! Map) return {};
    final rawData = message['__data'];
    if (rawData == null) return {};
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  /// Extracts a unique identifier for a message from various potential fields.
  static String? getMessageId(dynamic message) {
    if (message is! Map) return null;
    final id =
        message['whatsapp_message_id'] ??
        message['wamid'] ??
        message['_uid'] ??
        message['uid'] ??
        message['id'] ??
        message['local_id'];
    return id?.toString();
  }

  /// Gets stripped and trimmed text content from a message object.
  static String getNormalizedText(dynamic message) {
    if (message is! Map) return '';
    final String rawText =
        (message['message'] ?? message['message_body'] ?? message['text'] ?? '')
            .toString();
    if (rawText == 'Media')
      return 'Media'; // Special case for media placeholders
    return htmlToPlainText(rawText).trim();
  }

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String format24hCountdown(Duration duration) {
    if (duration.isNegative || duration.inSeconds == 0) return "expired";

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours >= 24) return "24 hours";

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
  /// Optimized with compiled RegExp.
  static final RegExp _brRegex = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final RegExp _emRegex = RegExp(r'</?em>', caseSensitive: false);
  static final RegExp _strongRegex = RegExp(
    r'</?(strong|b)>',
    caseSensitive: false,
  );
  static final RegExp _tagRegex = RegExp(r'<[^>]*>');

  static String htmlToPlainText(String? html) {
    if (html == null || html.isEmpty) return '';

    String text = html;
    text = text.replaceAll(_brRegex, '\n');
    text = text.replaceAll(_emRegex, '_');
    text = text.replaceAll(_strongRegex, '*');
    text = text.replaceAll(_tagRegex, '');

    // Efficient entity replacement
    if (text.contains('&')) {
      text = text
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'");
    }

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
          await [
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ].request();
        } else {
          await Permission.storage.request();
        }
      }

      String localPath = urlOrPath;

      if (urlOrPath.startsWith('http')) {
        final directory = await getApplicationDocumentsDirectory();
        final String name = fileName ?? urlOrPath.split('/').last;
        final String sanitizedName = name.replaceAll(
          RegExp(r'[^\w\s\.\-]'),
          '_',
        );
        localPath = '${directory.path}/$sanitizedName';

        final File file = File(localPath);

        if (!await file.exists()) {
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

      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done) {
        Fluttertoast.showToast(msg: result.message ?? "Could not open file");
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "No application available to open this file.",
      );
    }
  }

  /// Formats a message object into a WhatsApp-style preview string.
  static String getMessagePreview(Map<String, dynamic> contact) {
    final lastMessage = contact['last_message'];
    if (lastMessage is! Map) {
      final text = contact['latest_message_text'] ?? contact['message'];
      return text != null ? htmlToPlainText(text.toString()) : '';
    }

    String prefix = '';
    final bool isGroup =
        contact['is_group_chat'] == true || contact['is_group'] == true;

    if (isGroup) {
      final sender =
          lastMessage['sender_name'] ??
          lastMessage['vendor_messaging_user']?['name'];
      if (sender != null) prefix = '$sender: ';
    }

    if (lastMessage['is_deleted'] == true)
      return '${prefix}🚫 This message was deleted';

    String type = (lastMessage['message_type'] ?? lastMessage['type'] ?? '')
        .toString()
        .toLowerCase();

    switch (type) {
      case 'image':
        return '${prefix}🖼️ Photo';
      case 'video':
        return '${prefix}🎥 Video';
      case 'voice':
      case 'ptt':
      case 'audio':
        return '${prefix}🎤 Voice message';
      case 'sticker':
        return '${prefix}😊 Sticker';
      case 'document':
      case 'file':
        return '${prefix}📄 Document';
      default:
        final text =
            lastMessage['message'] ??
            lastMessage['text'] ??
            lastMessage['body'];
        if (text != null && text.toString() != 'Media')
          return '${prefix}${htmlToPlainText(text.toString())}';
        return '${prefix}📎 Media message';
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
