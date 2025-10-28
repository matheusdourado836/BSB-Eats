import 'package:bsb_eats/shared/widgets/user_avatar_widget.dart';
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

            return ListView.separated(
              itemCount: value.allUsers.length,
              physics: const AlwaysScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = value.allUsers[index];
                return ListTile(
                  horizontalTitleGap: 6,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => ProfilePictureSelected(
                        user: user,
                        currentUser: userController.currentUser!,
                      )
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: CachedNetworkImageProvider(
                        user.profilePhotoUrl ?? "",
                        errorListener: (e) => const NoBgUser(),
                      ),
                      onBackgroundImageError: (exception, stackTrace) => const NoBgUser()
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(user.username ?? ""),
                      Row(
                        children: [
                          Text('Admin:'),
                          if(userController.currentUser!.adminSupremo ?? false)
                            Transform.scale(
                              scale: .7,
                              child: Switch(
                                value: user.admin ?? false,
                                onChanged: (newValue) {
                                  userController.updateUserData({'admin': newValue}, userId: user.id!);
                                  user.admin = newValue;
                                  setState(() {});
                                }
                              ),
                            )
                          else
                            Checkbox(value: user.admin ?? false, onChanged: (value) {})
                        ],
                      )
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(user.nome ?? ""),
                      Row(
                        children: [
                          Text('Verificado:'),
                          Transform.scale(
                            scale: .7,
                            child: Switch(
                              value: user.verified ?? false,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (newValue) {
                                userController.updateUserData({'verified': newValue}, userId: user.id!);
                                user.verified = newValue;
                                setState(() {});
                              }
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                );
              }
            );
          },
        ),
      )
    );
  }
}