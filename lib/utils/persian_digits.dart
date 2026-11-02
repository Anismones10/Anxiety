/// Changes 0-9 to Persian digits ۰-۹ in a text.
String toPersianDigits(String text) {
  const digits = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final code in text.runes) {
    if (code >= 0x30 && code <= 0x39) {
      buffer.write(digits[code - 0x30]);
    } else {
      buffer.writeCharCode(code);
    }
  }
  return buffer.toString();
}
