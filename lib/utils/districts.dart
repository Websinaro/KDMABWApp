class KDistrict {
  final String key;
  final String label;
  final double lat;
  final double lon;

  const KDistrict(this.key, this.label, this.lat, this.lon);
}

/// Must stay in sync with the backend's `data/kerala_districts.py`.
const List<KDistrict> kKeralaDistricts = [
  KDistrict('thiruvananthapuram', 'Thiruvananthapuram', 8.5241, 76.9366),
  KDistrict('kollam', 'Kollam', 8.8932, 76.6141),
  KDistrict('pathanamthitta', 'Pathanamthitta', 9.2648, 76.7870),
  KDistrict('alappuzha', 'Alappuzha', 9.4981, 76.3388),
  KDistrict('kottayam', 'Kottayam', 9.5916, 76.5222),
  KDistrict('idukki', 'Idukki', 9.8500, 77.1000),
  KDistrict('ernakulam', 'Ernakulam', 9.9816, 76.2999),
  KDistrict('thrissur', 'Thrissur', 10.5276, 76.2144),
  KDistrict('palakkad', 'Palakkad', 10.7867, 76.6548),
  KDistrict('malappuram', 'Malappuram', 11.0510, 76.0711),
  KDistrict('kozhikode', 'Kozhikode', 11.2588, 75.7804),
  KDistrict('wayanad', 'Wayanad', 11.6854, 76.1320),
  KDistrict('kannur', 'Kannur', 11.8745, 75.3704),
  KDistrict('kasaragod', 'Kasaragod', 12.4996, 74.9869),
];

KDistrict? findDistrict(String key) {
  for (final d in kKeralaDistricts) {
    if (d.key == key) return d;
  }
  return null;
}

String districtLabel(String key) {
  final d = findDistrict(key);
  if (d != null) return d.label;
  if (key.isEmpty) return 'Unknown';
  return key[0].toUpperCase() + key.substring(1);
}
