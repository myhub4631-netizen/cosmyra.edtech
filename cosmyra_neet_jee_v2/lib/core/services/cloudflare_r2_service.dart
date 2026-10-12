import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudflareR2Service {
  // Environment or SharedPreferences Keys
  static const String _r2AccountIdKey = 'r2_account_id';
  static const String _r2AccessKeyIdKey = 'r2_access_key_id';
  static const String _r2SecretAccessKeyKey = 'r2_secret_access_key';
  static const String _r2BucketNameKey = 'r2_bucket_name';
  static const String _r2PublicDomainKey = 'r2_public_domain';

  // Default / Configured values (Can be overridden via saveConfig or .env)
  static String accountId = const String.fromEnvironment('R2_ACCOUNT_ID', defaultValue: '');
  static String accessKeyId = const String.fromEnvironment('R2_ACCESS_KEY_ID', defaultValue: '');
  static String secretAccessKey = const String.fromEnvironment('R2_SECRET_ACCESS_KEY', defaultValue: '');
  static String bucketName = const String.fromEnvironment('R2_BUCKET_NAME', defaultValue: 'question-bank-assets');
  static String publicDomain = const String.fromEnvironment('R2_PUBLIC_DOMAIN', defaultValue: '');

  static bool get isConfigured =>
      accountId.isNotEmpty && accessKeyId.isNotEmpty && secretAccessKey.isNotEmpty;

  static String _cleanDomain(String d) {
    var domain = d.trim().replaceAll(RegExp(r'/$'), '');
    if (domain.isNotEmpty && !domain.startsWith('http://') && !domain.startsWith('https://')) {
      domain = 'https://$domain';
    }
    return domain;
  }

  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acc = prefs.getString(_r2AccountIdKey);
      final keyId = prefs.getString(_r2AccessKeyIdKey);
      final secret = prefs.getString(_r2SecretAccessKeyKey);
      final bucket = prefs.getString(_r2BucketNameKey);
      final domain = prefs.getString(_r2PublicDomainKey);

      if (acc != null && acc.isNotEmpty) accountId = acc;
      if (keyId != null && keyId.isNotEmpty) accessKeyId = keyId;
      if (secret != null && secret.isNotEmpty) secretAccessKey = secret;
      if (bucket != null && bucket.isNotEmpty) bucketName = bucket;
      if (domain != null && domain.isNotEmpty) publicDomain = _cleanDomain(domain);

      // Also fetch R2 configuration from Supabase system_config table so any student/user device gets the global R2 setup
      try {
        final supa = Supabase.instance.client;
        final res = await supa
            .from('system_config')
            .select('value')
            .or('key.eq.cloudflare_r2_config,key.eq.r2_config')
            .maybeSingle();

        if (res != null && res['value'] != null) {
          final rawVal = res['value'];
          Map<String, dynamic>? data;
          if (rawVal is Map<String, dynamic>) {
            data = rawVal;
          } else if (rawVal is String && rawVal.isNotEmpty) {
            try {
              data = jsonDecode(rawVal) as Map<String, dynamic>;
            } catch (_) {}
          }

          if (data != null) {
            final cloudAcc = (data['account_id'] ?? data['r2_account_id'] ?? '').toString().trim();
            final cloudKeyId = (data['access_key_id'] ?? data['r2_access_key_id'] ?? '').toString().trim();
            final cloudSecret = (data['secret_access_key'] ?? data['r2_secret_access_key'] ?? '').toString().trim();
            final cloudBucket = (data['bucket_name'] ?? data['r2_bucket_name'] ?? '').toString().trim();
            final cloudDomain = (data['public_domain'] ?? data['r2_public_domain'] ?? '').toString().trim();

            if (cloudAcc.isNotEmpty) accountId = cloudAcc;
            if (cloudKeyId.isNotEmpty) accessKeyId = cloudKeyId;
            if (cloudSecret.isNotEmpty) secretAccessKey = cloudSecret;
            if (cloudBucket.isNotEmpty) bucketName = cloudBucket;
            if (cloudDomain.isNotEmpty) publicDomain = _cleanDomain(cloudDomain);

            if (accountId.isNotEmpty) await prefs.setString(_r2AccountIdKey, accountId);
            if (accessKeyId.isNotEmpty) await prefs.setString(_r2AccessKeyIdKey, accessKeyId);
            if (secretAccessKey.isNotEmpty) await prefs.setString(_r2SecretAccessKeyKey, secretAccessKey);
            if (bucketName.isNotEmpty) await prefs.setString(_r2BucketNameKey, bucketName);
            if (publicDomain.isNotEmpty) await prefs.setString(_r2PublicDomainKey, publicDomain);
          }
        }
      } catch (e) {
        debugPrint('Notice loading Cloudflare R2 config from Supabase: $e');
      }
    } catch (e) {
      debugPrint('Notice loading R2 config: $e');
    }
  }

  static Future<void> saveConfig({
    required String accountIdVal,
    required String accessKeyIdVal,
    required String secretAccessKeyVal,
    required String bucketNameVal,
    required String publicDomainVal,
  }) async {
    accountId = accountIdVal.trim();
    accessKeyId = accessKeyIdVal.trim();
    secretAccessKey = secretAccessKeyVal.trim();
    bucketName = bucketNameVal.trim();
    publicDomain = _cleanDomain(publicDomainVal);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_r2AccountIdKey, accountId);
    await prefs.setString(_r2AccessKeyIdKey, accessKeyId);
    await prefs.setString(_r2SecretAccessKeyKey, secretAccessKey);
    await prefs.setString(_r2BucketNameKey, bucketName);
    await prefs.setString(_r2PublicDomainKey, publicDomain);

    // Persist to Supabase system_config table so ALL users & devices get the R2 credentials automatically
    try {
      final supa = Supabase.instance.client;
      final payload = {
        'account_id': accountId,
        'access_key_id': accessKeyId,
        'secret_access_key': secretAccessKey,
        'bucket_name': bucketName,
        'public_domain': publicDomain,
      };
      await supa.from('system_config').upsert({
        'key': 'cloudflare_r2_config',
        'value': jsonEncode(payload),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notice persisting Cloudflare R2 config to Supabase system_config: $e');
    }
  }

  /// Uploads binary file bytes directly to Cloudflare R2 bucket via S3 API V4 Signature
  /// Returns the short public CDN URL (e.g. https://pub-r2.dev/uploads/123456_file.png)
  static Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    String mimeType = 'image/png',
  }) async {
    await loadConfig();

    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final objectKey = 'uploads/${DateTime.now().millisecondsSinceEpoch}_$cleanName';

    if (!isConfigured) {
      debugPrint('Cloudflare R2 is not configured yet. Returning null for fallback handlers.');
      return null;
    }

    final region = 'auto';
    final service = 's3';

    final host = '$accountId.r2.cloudflarestorage.com';
    final endpointUrl = Uri.parse('https://$host/$bucketName/$objectKey');

    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);

    final payloadHash = sha256.convert(fileBytes).toString();

    final canonicalHeaders =
        'host:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest = [
      'PUT',
      '/$bucketName/$objectKey',
      '',
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    final signingKey = _getSignatureKey(secretAccessKey, dateStamp, region, service);
    final signature = Hmac(sha256, signingKey)
        .convert(utf8.encode(stringToSign))
        .toString();

    final authorizationHeader =
        'AWS4-HMAC-SHA256 Credential=$accessKeyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    try {
      final response = await http.put(
        endpointUrl,
        headers: {
          'Host': host,
          'Content-Type': mimeType,
          'x-amz-date': amzDate,
          'x-amz-content-sha256': payloadHash,
          'Authorization': authorizationHeader,
        },
        body: fileBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicBase = publicDomain.isNotEmpty ? publicDomain : 'https://$host/$bucketName';
        return '$publicBase/$objectKey';
      } else {
        debugPrint('R2 Upload Failed [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error uploading file to Cloudflare R2: $e');
    }

    return null;
  }

  /// Lists all objects in the Cloudflare R2 bucket via S3 ListObjectsV2 API
  static Future<List<Map<String, dynamic>>> listBucketFiles() async {
    await loadConfig();
    if (!isConfigured) return [];

    final region = 'auto';
    final service = 's3';
    final host = '$accountId.r2.cloudflarestorage.com';
    final endpointUrl = Uri.parse('https://$host/$bucketName?list-type=2');

    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);

    final payloadHash = sha256.convert(utf8.encode('')).toString();

    final canonicalHeaders =
        'host:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest = [
      'GET',
      '/$bucketName',
      'list-type=2',
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    final signingKey = _getSignatureKey(secretAccessKey, dateStamp, region, service);
    final signature = Hmac(sha256, signingKey)
        .convert(utf8.encode(stringToSign))
        .toString();

    final authorizationHeader =
        'AWS4-HMAC-SHA256 Credential=$accessKeyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    try {
      final response = await http.get(
        endpointUrl,
        headers: {
          'Host': host,
          'x-amz-date': amzDate,
          'x-amz-content-sha256': payloadHash,
          'Authorization': authorizationHeader,
        },
      );

      if (response.statusCode == 200) {
        final results = <Map<String, dynamic>>[];
        final xmlStr = response.body;

        final keyRegExp = RegExp(r'<Key>(.*?)</Key>');
        final sizeRegExp = RegExp(r'<Size>(.*?)</Size>');
        final modRegExp = RegExp(r'<LastModified>(.*?)</LastModified>');

        final contentsBlocks = xmlStr.split('<Contents>');
        for (var i = 1; i < contentsBlocks.length; i++) {
          final block = contentsBlocks[i].split('</Contents>').first;
          final keyMatch = keyRegExp.firstMatch(block);
          final sizeMatch = sizeRegExp.firstMatch(block);
          final modMatch = modRegExp.firstMatch(block);

          if (keyMatch != null) {
            final key = keyMatch.group(1) ?? '';
            if (key.isNotEmpty && !key.endsWith('/')) {
              final sizeBytes = int.tryParse(sizeMatch?.group(1) ?? '0') ?? 0;
              final lastMod = modMatch?.group(1) ?? DateTime.now().toIso8601String();

              final publicBase = publicDomain.isNotEmpty ? publicDomain : 'https://$host/$bucketName';
              final publicUrl = '$publicBase/$key';

              results.add({
                'key': key,
                'size_bytes': sizeBytes,
                'size_kb': (sizeBytes / 1024).ceil(),
                'last_modified': lastMod,
                'public_url': publicUrl,
              });
            }
          }
        }
        return results;
      } else {
        debugPrint('R2 ListObjects Failed [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error listing files from Cloudflare R2: $e');
    }

    return [];
  }

  // --- Helper Signing Functions ---
  static List<int> _getSignatureKey(
      String key, String dateStamp, String regionName, String serviceName) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$key')).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(regionName)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(serviceName)).bytes;
    final kSigning = Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
    return kSigning;
  }

  static String _formatAmzDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}Z';
  }

  static String _formatDateStamp(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
