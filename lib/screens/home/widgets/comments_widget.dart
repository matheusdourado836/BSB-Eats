import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/shared/model/comment.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '../../../controller/user_controller.dart';
import '../../../shared/model/post.dart';
import '../../../shared/widgets/post_page_error_widget.dart';
import '../../../shared/widgets/user_avatar_widget.dart';
import 'comments_skeleton.dart';

class CommentsSection extends StatefulWidget {
  final Post post;
  final String ownerName;
  final int qtdComments;
  const CommentsSection({super.key, required this.post, required this.ownerName, required this.qtdComments});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final SocialMediaController _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  late final _userController = Provider.of<UserController>(context, listen: false);
  PagingState<DocumentSnapshot?, Comment> _state = PagingState();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  MyUser? answeringUser;
  String? selectedCommentId;
  List<bool> hiddenAnswers = [];

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

  Future<void> _handleSendComment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = _userController.currentUser!;
    final comment = Comment(
      authorId: user.id!,
      authorName: user.username,
      authorPhoto: user.profilePhotoUrl,
      verifiedUser: user.verified,
      text: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      if (answeringUser != null) {
        await _socialMediaController.postCommentAnswer(
          postId: widget.post.id!,
          commentId: selectedCommentId!,
          comment: comment,
          postOwnerId: widget.post.authorID,
          replyAuthorId: _userController.currentUser?.id,
          replyAuthorName: _userController.currentUser?.username,
        );
        final selected = _state.items?.firstWhere((c) => c.id == selectedCommentId, orElse: () => Comment());
        if(selected?.id != null) {
          selected!.qtdAnswers = (selected.qtdAnswers ?? 0) + 1;
          selected.answers ??= [];
          selected.answers!.add(comment);
        }
      } else {
        await _socialMediaController.postComment(
          postId: widget.post.id!,
          postAuthorId: widget.post.authorID!,
          comment: comment,
        );
        widget.post.qtdComentarios = (widget.post.qtdComentarios ?? 0) + 1;
        hiddenAnswers.insert(0, false);
        final firstPage = List<Comment>.from(_state.pages?[0] ?? []);
        firstPage.insert(0, comment);
        _state = _state.copyWith(
          pages: [firstPage, ..._state.pages?.sublist(1) ?? []]
        );
      }
    } finally {
      _commentController.clear();
      answeringUser = null;
      selectedCommentId = null;
      _focusNode.unfocus();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _commentFormSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextFormField(
            controller: _commentController,
            focusNode: _focusNode,
            validator: (value) => value?.isEmpty ?? true
                ? 'o comentário é obrigatório'
                : null,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: answeringUser != null ? 'Digite a resposta aqui...' : 'Adicione um comentário para ${widget.ownerName}',
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
            onPressed: _handleSendComment,
            iconSize: 18,
            icon: const Icon(Icons.send),
          )
      ],
    );
  }

  Future<void> loadCommentAnswers(Comment comentario, int index) async {
    if(comentario.answers?.length == comentario.qtdAnswers) {
      setState(() => hiddenAnswers[index] = !hiddenAnswers[index]);
    }else if((comentario.answers?.length ?? 0) < (comentario.qtdAnswers ?? 0)) {
      try{
        setState(() => comentario.loadingAnswers = true);
        final newAnswers = await _socialMediaController.fetchCommentAnswers(
          postId: widget.post.id,
          commentId: comentario.id!,
          startAfter: comentario.lastAnswerDoc,
          pageSize: 3
        );
        final answers = newAnswers.map((doc) async {
          final user = await _userController.getUserById((doc.data()! as Map<String, dynamic>)["authorId"]);
          return Comment(
            id: doc.id,
            authorId: user?.id,
            authorName: user?.username,
            authorPhoto: user?.profilePhotoUrl,
            verifiedUser: user?.verified,
            text: (doc.data()! as Map<String, dynamic>)["text"],
            createdAt: DateTime.tryParse((doc.data()! as Map<String, dynamic>)["createdAt"]),
          );
        }).toList();
        final newComments = await Future.wait(answers);
        comentario.answers ??= [];
        final commentsIds = comentario.answers!.map((c) => c.id).nonNulls.toList();
        newComments.removeWhere((c) => commentsIds.contains(c.id));
        newComments.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
        comentario.answers!.addAll(newComments);
        comentario.lastAnswerDoc = newAnswers.lastOrNull;
      }catch(e) {
        comentario.answers = [];
      }finally {
        setState(() => comentario.loadingAnswers = false);
      }
    }
  }

  void _fetchNextPage() async {
    if (_state.isLoading) return;

    setState(() {
      _state = _state.copyWith(isLoading: true, error: null);
    });

    try {
      List<Comment> newItems = await _socialMediaController.getComments(
        pageSize: 6,
        postId: widget.post.id!,
      );
      final isLastPage = newItems.isEmpty;

      setState(() {
        _state = _state.copyWith(
          pages: [...?_state.pages, newItems],
          keys: [...?_state.keys, _socialMediaController.lastCommentDoc],
          hasNextPage: !isLastPage,
          isLoading: false,
        );
      });
    } catch (error) {
      setState(() {
        _state = _state.copyWith(
          error: error,
          isLoading: false,
        );
      });
    }
  }

  Widget _noCommentsFound() => const Center(
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

  Future<void> _deleteComment(String cId, bool isAnswer, {String? answerId}) async {
    if(isAnswer) {
      await _socialMediaController.deleteCommentAnswer(
        postId: widget.post.id!,
        commentId: cId,
        answerId: answerId!
      );
      final comment = _state.items?.firstWhere((c) => c.id == cId);
      comment?.answers?.removeWhere((element) => element.id == answerId);
      comment?.qtdAnswers = (comment.qtdAnswers ?? 0) - 1;
    }else {
      await _socialMediaController.deleteComment(postId: widget.post.id!, commentId: cId);
      widget.post.qtdComentarios = (widget.post.qtdComentarios ?? 0) - 1;
      final index = _state.items?.indexWhere((com) => com.id == cId);
      if(index != null && index != -1) {
        hiddenAnswers.removeAt(index);
      }
      final pages = List<List<Comment>>.from(_state.pages ?? []);
      final c = _state.items?.firstWhere((com) => com.id == cId);
      final i = pages.indexWhere((page) => page.contains(c));
      if(i != -1) {
        final items = List<Comment>.from(pages[i]);
        items.removeWhere((element) => element.id == cId);
        pages[i] = items;
        _state = _state.copyWith(pages: pages);
      }
    }
    setState(() {});
    Navigator.pop(context);
    showCustomSnackBar(child: const Text('Comentário removido com sucesso'));
  }

  @override
  void initState() {
    hiddenAnswers = List.generate(widget.qtdComments, (index) => false);
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
              child: PagedListView<DocumentSnapshot?, Comment>(
                state: _state,
                fetchNextPage: _fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<Comment>(
                  itemBuilder: (context, comentario, index) => CommentRow(
                    key: UniqueKey(),
                    comentario: comentario,
                    post: widget.post,
                    isHidden: hiddenAnswers.isEmpty ? false : hiddenAnswers[index],
                    onCommentTap: () {
                      if(comentario.authorId == _userController.currentUser?.id) {
                        Navigator.pushNamed(context, '/user_profile');
                      }else {
                        Navigator.pushNamed(context, '/profile', arguments: comentario.authorId);
                      }
                    },
                    onAnswerTap: () {
                      _focusNode.requestFocus();
                      selectedCommentId = comentario.id!;
                      setState(() => answeringUser = MyUser(
                          id: comentario.authorId,
                          username: comentario.authorName,
                          profilePhotoUrl: comentario.authorPhoto
                      ));
                    },
                    onShowButtonTap: () => loadCommentAnswers(comentario, index),
                    onDeleteComment: (comment, isAnswer, {String? answerId}) => _deleteComment(comment, isAnswer, answerId: answerId)
                  ),
                  firstPageProgressIndicatorBuilder: (context) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: CommentsSkeleton(),
                  ),
                  firstPageErrorIndicatorBuilder: (context) {
                    return FirstPageExceptionIndicator(
                        title: 'Erro ao carregar comentários',
                        message: 'Algo não saiu como esperado...',
                        onTryAgain: () => setState(() => _state.reset())
                    );
                  },
                  noItemsFoundIndicatorBuilder: (context) => _noCommentsFound(),
                  newPageProgressIndicatorBuilder: (context) => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            if(_userController.currentUser != null)
              Column(
                children: [
                  if(answeringUser != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(left: 16),
                      color: theme().primaryColor.withValues(alpha: .7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Respondendo a ${answeringUser!.username}...',
                              style: TextStyle(color: theme().colorScheme.onPrimary, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              answeringUser = null;
                              selectedCommentId = null;
                              _focusNode.unfocus();
                            }),
                            color: theme().colorScheme.onPrimary,
                            icon: const Icon(Icons.close)
                          )
                        ],
                      ),
                    ),
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
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}

class CommentRow extends StatelessWidget {
  final Comment comentario;
  final Post post;
  final bool isHidden;
  final void Function()? onCommentTap;
  final void Function()? onAnswerTap;
  final void Function()? onShowButtonTap;
  final void Function(String commentId, bool isAnswer, {String? answerId}) onDeleteComment;
  const CommentRow({
    super.key,
    required this.comentario,
    required this.post,
    required this.isHidden,
    this.onCommentTap,
    this.onAnswerTap,
    this.onShowButtonTap,
    required this.onDeleteComment
  });

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onCommentTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserRow(
              comment: comentario,
              commentId: comentario.id!,
              post: post,
              currentUserId: userController.currentUser?.id,
              isAnswer: false,
              onCommentTap: onCommentTap,
              onAnswerTap: onAnswerTap,
              onDeleteComment: onDeleteComment,
            ),
            if(comentario.answers?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: SizedBox(
                  height: isHidden ? 0 : null,
                  child: ListView.builder(
                    itemCount: comentario.answers!.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final answer = comentario.answers![index];
                      return UserRow(
                        comment: answer,
                        post: post,
                        currentUserId: userController.currentUser?.id,
                        isAnswer: true,
                        answerId: answer.id!,
                        commentId: comentario.id,
                        onCommentTap: onCommentTap,
                        onAnswerTap: onAnswerTap,
                        onDeleteComment: onDeleteComment,
                      );
                    }
                  ),
                ),
              ),
            if((comentario.qtdAnswers ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Row(
                  spacing: 6,
                  children: [
                    Container(
                      width: 24,
                      height: 1,
                      color: Theme.of(context).primaryColor.withValues(alpha: .5),
                    ),
                    InkWell(
                      onTap: onShowButtonTap,
                      child: Row(
                        spacing: 6,
                        children: [
                          Text(
                            (comentario.answers?.length == comentario.qtdAnswers && isHidden == false)
                              ? 'Ocultar respostas'
                              : isHidden
                                ? 'Ver ${comentario.qtdAnswers} respostas'
                                : 'Ver mais ${(comentario.qtdAnswers ?? 0) - (comentario.answers?.length ?? 0)} respostas'
                          ),
                          if(comentario.loadingAnswers == true)
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 1,),
                            )
                        ],
                      ),
                    )
                  ],
                ),
              ),
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
  final bool isAnswer;
  final String? answerId;
  final String? commentId;
  final void Function()? onCommentTap;
  final void Function()? onAnswerTap;
  final void Function(String commentId, bool isAnswer, {String? answerId}) onDeleteComment;
  const UserRow({
    super.key,
    required this.comment,
    required this.post,
    required this.currentUserId,
    required this.isAnswer,
    this.answerId,
    this.commentId,
    this.onCommentTap,
    this.onAnswerTap,
    required this.onDeleteComment
  });

  @override
  State<UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<UserRow> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onCommentTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(widget.comment.authorPhoto?.isNotEmpty ?? false)
            CircleAvatar(
              radius: widget.isAnswer ? 18 : 20,
              backgroundImage: CachedNetworkImageProvider(widget.comment.authorPhoto!),
            )
          else NoBgUser(radius: 18, username: widget.comment.authorName),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              spacing: 4,
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
                                Text(
                                  widget.comment.authorName ?? 'anôninmo',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: widget.isAnswer ? 10 : 12,
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                                if(widget.comment.verifiedUser == true)
                                  const Icon(Icons.verified, size: 12, color: Colors.blue)
                              ],
                            )
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.circle, size: 4, color: Color.fromRGBO(167, 165, 165, 1))
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
                                    onPressed: () => widget.onDeleteComment(widget.commentId!, widget.isAnswer, answerId: widget.answerId),
                                    style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                                    child: const Text('Remover comentário?')
                                  )
                                ],
                              ),
                            ),
                          )
                        ),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.delete),
                        iconSize: 18,
                        color: Colors.red
                      )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 32.0),
                  child: Text(widget.comment.text!, textAlign: TextAlign.justify, style: const TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: widget.onAnswerTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    visualDensity: VisualDensity.compact,
                    //tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: TextStyle(fontSize: 12)
                  ),
                  child: const Text('Responder')
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}