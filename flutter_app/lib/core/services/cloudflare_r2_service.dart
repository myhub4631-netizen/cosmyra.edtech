import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      if (domain != null && domain.isNotEmpty) publicDomain = domain;
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
    publicDomain = publicDomainVal.trim().replaceAll(RegExp(r'/$'), '');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_r2AccountIdKey, accountId);
    await prefs.setString(_r2AccessKeyIdKey, accessKeyId);
    await prefs.setString(_r2SecretAccessKeyKey, secretAccessKey);
    await prefs.setString(_r2BucketNameKey, bucketName);
    await prefs.setString(_r2PublicDomainKey, publicDomain);
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
