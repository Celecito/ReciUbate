import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class edit_profile extends StatefulWidget {
  const edit_profile({super.key});

  @override
  State<edit_profile> createState() => _edit_profileState();
}

class _edit_profileState extends State<edit_profile> {

  final _nameController = TextEditingController();
  final _photoController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    _nameController.text = user?.displayName ?? "";
    _photoController.text = user?.photoURL ?? "";
  }

  Future<void> actualizarPerfil() async {
    try {
      await user?.updateDisplayName(_nameController.text);
      await user?.updatePhotoURL(_photoController.text);

      await user?.reload();

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil actualizado"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: const Color(0xFF238501),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre",
              ),
            ),


            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: actualizarPerfil,
              child: const Text("Guardar cambios"),
            )

          ],
        ),
      ),
    );
  }
}