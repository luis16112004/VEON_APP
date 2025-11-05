import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veon_app/models/provider.dart';

class ProviderService {
  static const String _providersKey = 'providers';

  Future<List<Provider>> getProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final providersJson = prefs.getString(_providersKey);
      
      if (providersJson == null) {
        return [];
      }

      final List<dynamic> providersList = json.decode(providersJson);
      return providersList.map((json) => Provider.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveProvider(Provider provider) async {
    try {
      final providers = await getProviders();
      providers.add(provider);
      
      final prefs = await SharedPreferences.getInstance();
      final providersJson = json.encode(
        providers.map((p) => p.toJson()).toList(),
      );
      
      return await prefs.setString(_providersKey, providersJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProvider(Provider provider) async {
    try {
      final providers = await getProviders();
      final index = providers.indexWhere((p) => p.id == provider.id);
      
      if (index == -1) {
        return false;
      }

      providers[index] = provider;
      
      final prefs = await SharedPreferences.getInstance();
      final providersJson = json.encode(
        providers.map((p) => p.toJson()).toList(),
      );
      
      return await prefs.setString(_providersKey, providersJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProvider(String providerId) async {
    try {
      final providers = await getProviders();
      providers.removeWhere((p) => p.id == providerId);
      
      final prefs = await SharedPreferences.getInstance();
      final providersJson = json.encode(
        providers.map((p) => p.toJson()).toList(),
      );
      
      return await prefs.setString(_providersKey, providersJson);
    } catch (e) {
      return false;
    }
  }
}
