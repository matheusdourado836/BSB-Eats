import 'package:bsb_eats/controller/auth_controller.dart';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/model/app_feedback.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/change_pass_modal.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/edit_profile_modal.dart';

class ProfileConfigScreen extends StatefulWidget {
  const ProfileConfigScreen({super.key});

  @override
  State<ProfileConfigScreen> createState() => _ProfileConfigScreenState();
}

class _ProfileConfigScreenState extends State<ProfileConfigScreen> {
  late final authController = Provider.of<AuthController>(context, listen: false);
  late final user = authController.currentUser!;

  Widget _userBg() {
    if(authController.currentUser!.profilePhotoUrl?.isEmpty ?? true) {
      final username = authController.currentUser!.nome?.initials();
      return CircleAvatar(
        radius: 70,
        backgroundColor: theme().primaryColor,
        child: Text(
          username ?? 'SN',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      );
    }

    return CircleAvatar(
      radius: 70,
      backgroundImage: NetworkImage(authController.currentUser!.profilePhotoUrl!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações de perfil"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _userBg(),
            const SizedBox(height: 12),
            Text(
              '@${user.username ?? 'sem nome'}',
              style: theme().textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email ?? 'sem email',
              style: theme().textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Divider(thickness: 1, height: 32, color: Colors.grey[300]),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar perfil'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                useSafeArea: true,
                barrierColor: theme().scaffoldBackgroundColor,
                backgroundColor: theme().scaffoldBackgroundColor,
                builder: (context) => const EditProfileModal()
              ).then((res) {
                if(res == true) {
                  showCustomSnackBar(child: Text('Informações atualizadas com sucesso!'));
                  setState(() {});
                }
              }),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Alterar senha'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => showModalBottomSheet(
                context: context,
                showDragHandle: true,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (context) => const ChangePassModal()
              ).then((res) {
                if(res == true) {
                  showCustomSnackBar(child: Text('Senha alterada com sucesso!'));
                }
              }),
            ),
            if(authController.currentUser!.admin == true)
              ListTile(
                onTap: () => Navigator.pushNamed(context, '/admin'),
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Painel de adminstrador'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              onTap: () => launchUrl(Uri.parse('https://bsbeats-hub.lovable.app')),
              leading: const Icon(Icons.help),
              title: const Text('Suporte'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => FeedbackWidget(user: user)
                ).then((res) async {
                  if(res == true) {
                    showCustomTopSnackBar(text: 'Obrigado pelo feedback 😊');
                    final InAppReview inAppReview = InAppReview.instance;

                    if (await inAppReview.isAvailable()) {
                      inAppReview.requestReview();
                    }
                  }
                });
              },
              leading: const Icon(Icons.feedback),
              title: const Text('Enviar feedback'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Excluir conta', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
              onTap: () => showDialog(
                context: context,
                builder: (context) => const DeleteAccountDialog()
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => showModalBottomSheet(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Text('Confirmar Ação', style: theme().textTheme.bodyLarge,),
                      const SizedBox(height: 8),
                      Text('Deseja realmente sair da sua conta?', style: theme().textTheme.bodyMedium,),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => authController.logout().whenComplete(() => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)),
                        child: Text('Sair')
                      ),
                      const SizedBox(height: 24)
                    ],
                  ),
                )
              ),
            ),
            const SizedBox(height: 60),
            const Text('Versão', style: TextStyle(fontSize: 12)),
            Text('1.1.3', style: TextStyle(fontSize: 12))
          ],
        ),
      ),
    );
  }
}

class FeedbackWidget extends StatelessWidget {
  final MyUser user;
  const FeedbackWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
    return AlertDialog(
      title: Text('Deixe um feedback sobre o app'),
      content: SizedBox(
        height: 200,
        child: TextField(
          controller: textController,
          textAlignVertical: TextAlignVertical.top,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: 'Escreva seu feedback aqui...',
            border: OutlineInputBorder()
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final userController = Provider.of<UserController>(context, listen: false);
            final feedback = AppFeedback(
              authorId: user.id,
              text: textController.text
            );
            userController.sendFeedback(feedback: feedback);
            Navigator.pop(context, true);
          },
          child: const Text('Enviar')
        )
      ],
    );
  }
}
