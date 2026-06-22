import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme.dart';

class UpdateInfo {
  final bool available;
  final String latest;
  final String url;
  UpdateInfo(this.available, this.latest, this.url);
}

class UpdateService {
  /// Uses the releases list (not /latest) so beta/prerelease tags are seen too.
  static Future<UpdateInfo?> check() async {
    try {
      final res = await http
          .get(
            Uri.parse('https://api.github.com/repos/$kRepo/releases?per_page=1'),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      final j = list.first as Map<String, dynamic>;
      final tag = (j['tag_name'] as String? ?? '').replaceFirst('v', '');
      final url = j['html_url'] as String? ?? kRepoUrl;
      return UpdateInfo(_isNewer(tag, kAppVersion), tag, url);
    } catch (_) {
      return null;
    }
  }

  static bool _isNewer(String latest, String current) {
    final pa = latest.split(RegExp(r'[.+-]'));
    final pb = current.split(RegExp(r'[.+-]'));
    for (var i = 0; i < 3; i++) {
      final na = int.tryParse(i < pa.length ? pa[i] : '0') ?? 0;
      final nb = int.tryParse(i < pb.length ? pb[i] : '0') ?? 0;
      if (na != nb) return na > nb;
    }
    return false;
  }
}
