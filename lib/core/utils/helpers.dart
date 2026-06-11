import 'package:flutter/material.dart';

class Helpers {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    if (data is String) {
      return sanitizeString(data);
    } else if (data is Map) {
      return data.map((key, value) {
        final safeKey = key is String ? sanitizeString(key) : key;
        return MapEntry(safeKey, sanitizeData(value));
      });
    } else if (data is List) {
      return data.map((item) => sanitizeData(item)).toList();
    }
    return data;
  }
}
