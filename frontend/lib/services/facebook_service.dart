import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookService {
  Future<List<dynamic>> getFanpages() async {
    final AccessToken? token = await FacebookAuth.instance.accessToken;
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("https://graph.facebook.com/v25.0/me/accounts?fields=id,name,access_token&access_token=${token.token}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  Future<bool> postToFanpage(String pageId, String pageToken, String content) async {
    final response = await http.post(
      Uri.parse("https://graph.facebook.com/v25.0/$pageId/feed"),
      body: {
        "message": content,
        "access_token": pageToken,
      },
    );
    return response.statusCode == 200;
  }
}