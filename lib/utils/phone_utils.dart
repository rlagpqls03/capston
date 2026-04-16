class PhoneUtils {
  static String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  static String formatKoreanPhone(String raw) {
    final digits = digitsOnly(raw);
    if (digits.length < 10) return raw;
    if (digits.length <= 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    return '${limited.substring(0, 3)}-${limited.substring(3, 7)}-${limited.substring(7)}';
  }
}
