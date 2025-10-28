import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/user_avatar_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/user_controller.dart';

class PeopleListModal extends StatefulWidget {
  final String userId;
  final String field;
  const PeopleListModal({super.key, required this.userId, required this.field,});

  @override
  State<PeopleListModal> createState() => _PeopleListModalState();
}

class _PeopleListModalState extends State<PeopleListModal> {
  late final _userController = Provider.of<UserController>(context, listen: false);
  List<MyUser> users = [];

  Future<List<MyUser>> _getFollowers() async {
    if(users.isNotEmpty) return users;
    final followers = await _userController.getFollowersAndFollowing(userId: widget.userId, collection: widget.field);
    for(final follower in followers ?? []) {
      final user = await _userController.getUserById(follower.id);
      if(user != null) {
        users.add(user);
      }
    }

    return users;
  }

  Future<void> _removeFollower(MyUser user) async {
    final follower = Follower(
      id: user.id,
      nome: user.nome
    );
    if(widget.field == 'followers') {
      await _userController.removeFollower(follower);
      showCustomTopSnackBar(text: '${user.username} removido dos seguidores');
    }else {
      await _userController.toggleFollow(true, follower, _userController.currentUser!.username!);
      showCustomTopSnackBar(text: 'Você deixou de seguir ${user.username}');
    }
    setState(() => users.remove(user));
    if(users.isEmpty) {
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          Navigator.pop(context);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //TODO REMOVER ESSA LINHA NA PROXIMA ATUALIZACAO
          if(DateTime.now().month < 12)
            Center(child: Text('deslize para a direita para fechar')),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.field == 'followers' ? 'Seguidores' : 'Seguindo',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _getFollowers(),
              builder: (context, asyncSnapshot) {
                if(asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if(asyncSnapshot.hasError) {
                  return Center(
                    child: Text(asyncSnapshot.error.toString()),
                  );
                }
                final followers = asyncSnapshot.data;
                return ListView.builder(
                  itemCount: followers?.length ?? 0,
                  itemBuilder: (context, index) {
                    final person = followers?[index];
                    return ListTile(
                      onTap: () {
                        if(_userController.currentUser?.id == person?.id) {
                          Navigator.pushNamed(context, '/user_profile');
                        }else {
                          Navigator.pushNamed(context, '/profile', arguments: person?.id);
                        }
                      },
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: CachedNetworkImageProvider(
                          person?.profilePhotoUrl ?? '',
                          errorListener: (e) => const NoBgUser(),
                        ),
                      ),
                      title: Row(
                        spacing: 4,
                        children: [
                          Text(person?.username ?? 'anônimo'),
                          if(person?.verified == true)
                            const Icon(Icons.verified, size: 14, color: Colors.blue),
                        ],
                      ),
                      subtitle: Text(person?.nome ?? 'anônimo'),
                      trailing: widget.userId != _userController.currentUser?.id ? null : IconButton(
                        onPressed: () => _removeFollower(person!),
                        icon: const Icon(Icons.close),
                      )
                    );
                  }
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
