import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
}
