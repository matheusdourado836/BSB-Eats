import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/shared/model/comment.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/user_controller.dart';
import '../../../shared/model/post.dart';
import '../../../shared/widgets/user_avatar_widget.dart';
import 'comments_skeleton.dart';

class CommentsSection extends StatefulWidget {
  final Post post;
  final String ownerName;
  const CommentsSection({super.key, required this.post, required this.ownerName});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  late final SocialMediaController _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  late final _userController = Provider.of<UserController>(context, listen: false);
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Widget _loading() => Center(
    child: SizedBox(
      height: 25,
      width: 25,
      child: CircularProgressIndicator(
        color: theme().primaryColor,
        strokeWidth: 2,
      ),
    ),
  );

  Widget _commentFormSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextFormField(
            controller: _commentController,
            validator: (value) => value?.isEmpty ?? true
                ? 'o comentário é obrigatório'
                : null,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Adicione um comentário para ${widget.ownerName}',
              fillColor: theme().colorScheme.onPrimary,
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ),
        ),
        if(_isLoading)
          _loading()
        else
          IconButton.filled(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() => _isLoading = true);
                final comment = Comment(
                  authorId: _userController.currentUser!.id!,
                  authorName: _userController.currentUser!.username,
                  authorPhoto: _userController.currentUser!.profilePhotoUrl,
                  verifiedUser: _userController.currentUser!.verified,
                  text: _commentController.text,
                  createdAt: DateTime.now(),
                );
                _socialMediaController.postComment(postId: widget.post.id!, postAuthorId: widget.post.authorID!, comment: comment).whenComplete(() {
                  widget.post.qtdComentarios = (widget.post.qtdComentarios ?? 0) + 1;
                  _commentController.clear();
                  setState(() => _isLoading = false);
                  FocusScope.of(context).unfocus();
                });
              }
            },
            iconSize: 18,
            icon: const Icon(Icons.send),
          )
      ],
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _socialMediaController.getComments(postId: widget.post.id!));
    super.initState();
  }

  @override
  dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            Navigator.pop(context);
          }
        },
        child: Column(
          children: [
            const Text(
              'Comentários',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Expanded(
              child: Consumer<SocialMediaController>(
                builder: (context, value, _) {
                  if (value.loadingComments) {
                    return const CommentsSkeleton();
                  }

                  if (value.comments.isEmpty) {
                    return const Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Nenhum comentário ainda...\n',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20
                          ),
                          children: [
                            TextSpan(
                              text: 'inicie a conversa',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.black54,
                                fontSize: 16
                              )
                            )
                          ]
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: value.comments.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final comentario = value.comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                        child: InkWell(
                          onTap: () async {
                            if(comentario.authorId == _userController.currentUser?.id) {
                              Navigator.pushNamed(context, '/user_profile');
                            }else {
                              final user = await _userController.getUserById(comentario.authorId);
                              Navigator.pushNamed(context, '/profile', arguments: user?.id);
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(comentario.authorPhoto?.isNotEmpty ?? false)
                                CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                    comentario.authorPhoto!,
                                  ),
                                )
                              else const NoBgUser(radius: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: UserRow(
                                  comment: comentario,
                                  post: widget.post,
                                  currentUserId: _userController.currentUser?.id,
                                )
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if(_userController.currentUser != null)
              Container(
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    color: Theme.of(context).cardTheme.color
                ),
                padding: const EdgeInsets.all(12),
                child: SafeArea(
                  child: Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(_userController.currentUser?.profilePhotoUrl ?? ''),
                          onBackgroundImageError: (e, s) => const NoBgUser(),
                        ),
                        Expanded(child: _commentFormSection()),
                      ],
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class UserRow extends StatefulWidget {
  final Comment comment;
  final Post post;
  final String? currentUserId;
  const UserRow({super.key, required this.comment, required this.post, required this.currentUserId});

  @override
  State<UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<UserRow> {
  late final _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);

  Future<void> _deleteComment() async {
    await _socialMediaController.deleteComment(postId: widget.post.id!, commentId: widget.comment.id!);
    widget.post.qtdComentarios = (widget.post.qtdComentarios ?? 0) - 1;
    Navigator.pop(context);
    showCustomSnackBar(child: const Text('Comentário removido com sucesso'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Text(widget.comment.authorName ?? 'anôninmo', maxLines: 1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        if(widget.comment.verifiedUser == true)
                          const Icon(Icons.verified, size: 12, color: Colors.blue)
                      ],
                    )
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.circle, size: 4, color: Color.fromRGBO(167, 165, 165, 1),)
                  ),
                  Text(widget.comment.createdAt!.toFriendlyDate(), style: const TextStyle(fontSize: 8, color: Color.fromRGBO(167, 167, 167, 1)),)
                ],
              ),
            ),
            const SizedBox(width: 8),
            if(widget.post.authorID == widget.currentUserId || widget.comment.authorId == widget.currentUserId)
              IconButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextButton(
                            onPressed: () =>_deleteComment(),
                            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                            child: const Text('Remover comentário?')
                          )
                        ],
                      ),
                    ),
                  )
                ),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.delete),
                color: Colors.red
              )
            // TODO SECAO DE DENUNCIA DE COMENTARIOS
            // Material(
            //   color: Colors.transparent,
            //   child: InkWell(
            //       onTap: () => showDialog(
            //           context: context,
            //           builder: (context) => ReportDialog(postId: widget.devocionalId, comentario: widget.comment)
            //       ).then((res) {
            //         if(res == 1) {
            //           showCustomSnackBar(child: const Text('Denúncia enviada com sucesso!'));
            //         }
            //       }),
            //       splashColor: Colors.redAccent,
            //       radius: 40,
            //       borderRadius: BorderRadius.circular(50),
            //       child: const Icon(Icons.report_outlined, size: 24)
            //   ),
            // )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 32.0),
          child: Text(widget.comment.text!, textAlign: TextAlign.justify, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}