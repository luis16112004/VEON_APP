import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportUsersScreen extends StatefulWidget {
  const ExportUsersScreen({Key? key}) : super(key: key);

  @override
  State<ExportUsersScreen> createState() => _ExportUsersScreenState();
}

class _ExportUsersScreenState extends State<ExportUsersScreen> {
  bool _isExporting = false;
  String _result = '';

  Future<void> _exportUsers() async {
    setState(() {
      _isExporting = true;
      _result = '🔄 Exportando usuarios...\n\n';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('users').get();

      setState(() {
        _result += '📦 Total usuarios: ${snapshot.docs.length}\n';
        _result += '═══════════════════════════════════\n\n';
      });

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final userInfo = '''
👤 Usuario:
   Firebase ID: ${doc.id}
   Nombre: ${data['name'] ?? 'Sin nombre'}
   Email: ${data['email'] ?? 'Sin email'}
   Creado: ${data['createdAt'] ?? 'Fecha desconocida'}

''';

        setState(() {
          _result += userInfo;
        });

        // También imprime en consola
        print(userInfo);
      }

      setState(() {
        _result += '\n✅ Exportación completada';
        _isExporting = false;
      });

      print('✅ Exportación completada');
    } catch (e) {
      setState(() {
        _result += '\n❌ Error: $e';
        _isExporting = false;
      });
      print('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Usuarios de Firebase'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportUsers,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? 'Exportando...' : 'Exportar Usuarios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _result.isEmpty
                        ? 'Presiona el botón para exportar usuarios de Firebase.\n\nLos datos aparecerán aquí y en la consola.'
                        : _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tip: Los datos también se imprimen en la consola de Flutter',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
