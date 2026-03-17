import 'package:flutter_test/flutter_test.dart';
import 'package:rever_chat/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('shopifyStoreDomain has a non-empty default', () {
      expect(AppConfig.shopifyStoreDomain, isNotEmpty);
    });

    test('shopifyStoreDomain default ends with .myshopify.com', () {
      expect(
        AppConfig.shopifyStoreDomain.endsWith('.myshopify.com'),
        true,
        reason: 'Default domain should be a Shopify store URL',
      );
    });

    test('shopifyStorefrontToken has a non-empty default', () {
      expect(AppConfig.shopifyStorefrontToken, isNotEmpty);
    });

    test('shopifyStorefrontToken default is a 32-character hex string', () {
      final token = AppConfig.shopifyStorefrontToken;
      // 32 lowercase hex chars is the Shopify storefront token format
      expect(RegExp(r'^[a-f0-9]{32}$').hasMatch(token), true,
          reason: 'Default token should be a 32-char hex string');
    });

    test('firebaseProjectId is set', () {
      expect(AppConfig.firebaseProjectId, isNotEmpty);
    });

    test('firebaseProjectId matches expected project', () {
      expect(AppConfig.firebaseProjectId, 'rever-c494a');
    });

    test('firebaseAuthDomain is set', () {
      expect(AppConfig.firebaseAuthDomain, isNotEmpty);
    });

    test('firebaseAuthDomain uses correct project', () {
      expect(AppConfig.firebaseAuthDomain, contains('rever-c494a'));
    });

    test('firebaseApiKey is set and non-empty', () {
      expect(AppConfig.firebaseApiKey, isNotEmpty);
    });

    test('firebaseMessagingSenderId is set', () {
      expect(AppConfig.firebaseMessagingSenderId, isNotEmpty);
    });

    test('firebaseAppId is set', () {
      expect(AppConfig.firebaseAppId, isNotEmpty);
    });
  });
}
