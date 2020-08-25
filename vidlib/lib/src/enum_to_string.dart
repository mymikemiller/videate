// This class comes from the enum_to_string package, which is failing to import
// even after running `pub get` ("Target of URI doesn't exist"), so we're
// copying the code here. https://pub.dev/packages/enum_to_string
// Issue: https://github.com/rknell/flutterEnumsToString/issues/20
class EnumToString {
  static String parse(enumItem) {
    if (enumItem == null) return null;
    final _tmp = enumItem.toString().split('.')[1];
    return _tmp;
  }

  static T fromString<T>(List<T> enumValues, String value) {
    if (value == null || enumValues == null) return null;

    return enumValues.singleWhere(
        (enumItem) =>
            EnumToString.parse(enumItem)?.toLowerCase() == value?.toLowerCase(),
        orElse: () => null);
  }

  static int indexOf<T>(List<T> enumValues, String value) =>
      enumValues.indexOf(fromString<T>(enumValues, value));

  static List<String> toList<T>(List<T> enumValues) {
    if (enumValues == null) return null;
    final _enumList = enumValues.map((t) => EnumToString.parse(t)).toList();
    return _enumList;
  }
}
