String? parseShopIdFromLink(String link) {
  final uri = Uri.tryParse(link);
  if (uri == null) return null;

  if (uri.scheme == 'noqeu' && uri.host == 'shop' && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }

  if ((uri.host == 'noqeu.com' || uri.host == 'www.noqeu.com') &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments.first == 'shop') {
    return uri.pathSegments[1];
  }

  return null;
}
