import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/user_controller.dart';
import '../widgets/profile_picture_selected.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late final userController = Provider.of<UserController>(context, listen: false);

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required IconData icon,
    required Color activeColor,
    required ValueChanged<bool>? onChanged,
  }) {
    return Column(
      children: [
        Row(
          spacing: 4,
          children: [
            Icon(icon, size: 18, color: value ? activeColor : Colors.grey),
            Text(label),
          ],
        ),
        Transform.scale(
          scale: .8,
          child: Switch(
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => userController.fetchUsers());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Usuários"),
        centerTitle: true,
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => userController.fetchUsers(),
        child: Consumer<UserController>(
          builder: (context, value, _) {
            if(value.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if(value.allUsers.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 32,
                  children: [
                    Text("Nenhum usuário encontrado", textAlign: TextAlign.center,),
                    ElevatedButton(
                      onPressed: () => userController.fetchUsers(),
                      child: const Text("Tentar novamente"),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: value.allUsers.length,
              itemBuilder: (context, index) {
                final user = value.allUsers[index];
                final isSuperAdmin = userController.currentUser!.adminSupremo ?? false;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) => ProfilePictureSelected(
                              user: user,
                              currentUser: userController.currentUser!,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: user.profilePhotoUrl != null
                                ? CachedNetworkImageProvider(user.profilePhotoUrl!)
                                : null,
                            backgroundColor: Colors.grey.shade200,
                            child: user.profilePhotoUrl == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Infos e controles
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome e username
                              Text(
                                user.nome ?? 'Sem nome',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '@${user.username ?? ''}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0, bottom: 16),
                                child: Text(
                                  'Criado em ${user.createdAt?.toDate().formatted(includeTime: true) ?? ''}',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),

                              // Switches
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildToggleRow(
                                    label: 'Admin',
                                    value: user.admin ?? false,
                                    icon: Icons.admin_panel_settings,
                                    activeColor: Colors.indigo,
                                    onChanged: isSuperAdmin
                                        ? (newValue) {
                                      userController.updateUserData({'admin': newValue}, userId: user.id!);
                                      setState(() => user.admin = newValue);
                                      userController.sendUserStatusNotification(userId: user.id, type: 'admin', newValue: newValue);
                                    }
                                        : null,
                                  ),
                                  _buildToggleRow(
                                    label: 'Verificado',
                                    value: user.verified ?? false,
                                    icon: Icons.verified,
                                    activeColor: Colors.blue,
                                    onChanged: (newValue) {
                                      userController.updateUserData({'verified': newValue}, userId: user.id!);
                                      setState(() => user.verified = newValue);
                                      userController.sendUserStatusNotification(userId: user.id, type: 'verified', newValue: newValue);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      )
    );
  }
}