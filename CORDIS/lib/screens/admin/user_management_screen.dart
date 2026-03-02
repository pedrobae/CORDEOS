import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/user/admin_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGrantAdminCard(colorScheme),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                _buildStatusCard(colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrantAdminCard(ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Conceder Privilégios de Admin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Insira o email do usuário para conceder privilégios de administrador:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email do usuário',
                hintText: 'usuario@exemplo.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _grantAdminRole,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.security),
                label: Text(_isLoading ? 'Concedendo...' : 'Conceder Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      color: _isError ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _isError ? Icons.error : Icons.check_circle,
              color: _isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _isError ? Colors.red.shade800 : Colors.green.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _statusMessage = null;
                  _isError = false;
                });
              },
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _grantAdminRole() async {
    final email = _emailController.text.trim();

    // if (email.isEmpty) {
    //   _showStatus('Por favor, insira um email válido', isError: true);
    //   return;
    // }

    // if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
    //   _showStatus('Formato de email inválido', isError: true);
    //   return;
    // }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final adminProvider = context.read<AdminProvider>();

      // Grant admin role directly using the email
      await adminProvider.grantAdminRole(email);

      _showStatus(
        'Privilégios de admin concedidos com sucesso para $email!',
        isError: false,
      );

      // Clear the email field
      _emailController.clear();
    } catch (e) {
      _showStatus(
        'Erro ao conceder privilégios: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _isError = isError;
    });
  }
}
