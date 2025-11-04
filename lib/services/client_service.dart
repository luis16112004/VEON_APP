import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veon_app/models/client.dart';

class ClientService {
  static const String _clientsKey = 'clients';

  Future<List<Client>> getClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = prefs.getString(_clientsKey);
      
      if (clientsJson == null) {
        return [];
      }

      final List<dynamic> clientsList = json.decode(clientsJson);
      return clientsList.map((json) => Client.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveClient(Client client) async {
    try {
      final clients = await getClients();
      clients.add(client);
      
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = json.encode(
        clients.map((c) => c.toJson()).toList(),
      );
      
      return await prefs.setString(_clientsKey, clientsJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateClient(Client client) async {
    try {
      final clients = await getClients();
      final index = clients.indexWhere((c) => c.id == client.id);
      
      if (index == -1) {
        return false;
      }

      clients[index] = client;
      
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = json.encode(
        clients.map((c) => c.toJson()).toList(),
      );
      
      return await prefs.setString(_clientsKey, clientsJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteClient(String clientId) async {
    try {
      final clients = await getClients();
      clients.removeWhere((c) => c.id == clientId);
      
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = json.encode(
        clients.map((c) => c.toJson()).toList(),
      );
      
      return await prefs.setString(_clientsKey, clientsJson);
    } catch (e) {
      return false;
    }
  }
}




