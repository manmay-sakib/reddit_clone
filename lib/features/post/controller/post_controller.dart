import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reddit_clone/core/enums/enums.dart';
import 'package:reddit_clone/core/providers/storage_repository_provider.dart';
import 'package:reddit_clone/core/utils.dart';
import 'package:reddit_clone/features/post/repository/post_repository.dart';
import 'package:reddit_clone/features/user_profile/controller/user_profile_controller.dart';
import 'package:reddit_clone/model/community_model.dart';
import 'package:routemaster/routemaster.dart';
import 'package:uuid/uuid.dart';
import 'package:reddit_clone/model/comment_model.dart';

import '../../../model/post_model.dart';
import '../../auth/controller/auth_controller.dart';

final postControllerProvider =
    StateNotifierProvider<PostController, bool>((ref) {
  final postRepository = ref.watch(postRepositoryProvider);
  final storageRepository = ref.watch(storageRepositoryProvider);
  return PostController(
    postRepository: postRepository,
    ref: ref,
    storageRepository: storageRepository,
  );
});

final userPostsProvider =
    StreamProvider.family((ref, List<Community> communities) {
  final postController = ref.watch(postControllerProvider.notifier);
  return postController.fetchUserPosts(communities);
});

final guestPostsProvider = StreamProvider((ref) {
  final postController = ref.watch(postControllerProvider.notifier);
  return postController.fetchGuestPosts();
});

final getPostByIdProvider = StreamProvider.family((ref, String postId) {
  final postController = ref.watch(postControllerProvider.notifier);
  return postController.getPostById(postId);
});

final getPostCommentProvider = StreamProvider.family((ref, String postId) {
  final postController = ref.watch(postControllerProvider.notifier);
  return postController.fetchPostComments(postId);
});

class PostController extends StateNotifier<bool> {
  final PostRepository _postRepository;
  final Ref _ref;
  final StorageRepository _storageRepository;
  PostController({
    required PostRepository postRepository,
    required Ref ref,
    required StorageRepository storageRepository,
  })  : _storageRepository = storageRepository,
        _ref = ref,
        _postRepository = postRepository,
        super(false);

  void shareTextPost({
    required BuildContext context,
    required String title,
    required Community selectedCommunity,
    required String description,
  }) async {
    state = true;
    String postId = const Uuid().v1();
    final user = _ref.read(userProvider)!;
    final Post post = Post(
      type: 'text',
      uid: user.uid,
      communityName: selectedCommunity.name,
      id: postId,
      title: title,
      awards: [],
      commentCount: 0,
      communityProfilePic: selectedCommunity.avatar,
      createdAt: DateTime.now(),
      downvotes: [],
      upvotes: [],
      username: user.name,
      description: description,
    );

    final res = await _postRepository.addPost(post);
    _ref
        .read(userProfileControllerProvider.notifier)
        .updateUserKarma(UserKarma.textPost);
    state = false;
    res.fold((l) => showSnackBar(context, l.message), (r) {
      showSnackBar(context, 'Posted successfully!');
      Routemaster.of(context).pop();
    });
  }

  void shareLinkPost({
    required BuildContext context,
    required String title,
    required Community selectedCommunity,
    required String link,
  }) async {
    state = true;
    String postId = const Uuid().v1();
    final user = _ref.read(userProvider)!;
    final Post post = Post(
      type: 'link',
      uid: user.uid,
      communityName: selectedCommunity.name,
      id: postId,
      title: title,
      awards: [],
      commentCount: 0,
      communityProfilePic: selectedCommunity.avatar,
      createdAt: DateTime.now(),
      downvotes: [],
      upvotes: [],
      username: user.name,
      link: link,
    );

    final res = await _postRepository.addPost(post);
    _ref
        .read(userProfileControllerProvider.notifier)
        .updateUserKarma(UserKarma.linkPost);
    state = false;
    res.fold((l) => showSnackBar(context, l.message), (r) {
      showSnackBar(context, 'Posted successfully!');
      Routemaster.of(context).pop();
    });
  }

  void shareImagePost({
    required BuildContext context,
    required String title,
    required Community selectedCommunity,
    required File? file,
  }) async {
    state = true;
    String postId = const Uuid().v1();
    final user = _ref.read(userProvider)!;
    final imagesRes = await _storageRepository.storeFile(
      path: 'posts/${selectedCommunity.name}',
      id: postId,
      file: file,
    );
    imagesRes.fold((l) => showSnackBar(context, l.message), (r) async {
      final Post post = Post(
        type: 'image',
        uid: user.uid,
        communityName: selectedCommunity.name,
        id: postId,
        title: title,
        awards: [],
        commentCount: 0,
        communityProfilePic: selectedCommunity.avatar,
        createdAt: DateTime.now(),
        downvotes: [],
        upvotes: [],
        username: user.name,
        link: r,
      );

      final res = await _postRepository.addPost(post);
      _ref
          .read(userProfileControllerProvider.notifier)
          .updateUserKarma(UserKarma.imagePost);
      state = false;
      res.fold((l) => showSnackBar(context, l.message), (r) {
        showSnackBar(context, 'Posted successfully!');
        Routemaster.of(context).pop();
      });
    });
  }

  Stream<List<Post>> fetchUserPosts(List<Community> communities) {
    if (communities.isNotEmpty) {
      return _postRepository.fetchUserPosts(communities);
    }
    return Stream.value([]);
  }

  Stream<List<Post>> fetchGuestPosts() {
    return _postRepository.fetchGuestPosts();
  }

  void deletePost(Post post, BuildContext context) async {
    final res = await _postRepository.deletePost(post);
    res.fold((l) => null,
        (r) => showSnackBar(context, 'Post Deleted Successfully!'));
  }

  void upvote(Post post) async {
    final uid = _ref.read(userProvider)!.uid;
    _postRepository.upvote(post, uid);
  }

  void downvote(Post post) async {
    final uid = _ref.read(userProvider)!.uid;
    _postRepository.downvote(post, uid);
  }

  Stream<Post> getPostById(String postId) {
    return _postRepository.getPostById(postId);
  }

  void addComment(
      {required BuildContext context,
      required String text,
      required Post post}) async {
    final user = _ref.read(userProvider)!;
    String commentId = const Uuid().v1();
    Comment comment = Comment(
      id: commentId,
      text: text,
      createdAt: DateTime.now(),
      postId: post.id,
      username: user.name,
      profilePic: user.profilePic,
    );

    final res = await _postRepository.addComment(comment);
    _ref
        .read(userProfileControllerProvider.notifier)
        .updateUserKarma(UserKarma.comment);
    res.fold((l) => showSnackBar(context, l.message), (r) => null);
  }

  void awardPost({
    required Post post,
    required String award,
    required BuildContext context,
  }) async {
    final user = _ref.read(userProvider)!;
    final res = await _postRepository.awardPost(post, award, user.uid);

    res.fold((l) => showSnackBar(context, l.message), (r) {
      _ref
          .read(userProfileControllerProvider.notifier)
          .updateUserKarma(UserKarma.awardPost);
      _ref.read(userProvider.notifier).update((state) {
        state?.awards.remove(award);
        return state;
      });
      Routemaster.of(context).pop();
    });
  }

  Stream<List<Comment>> fetchPostComments(String postId) {
    return _postRepository.getCommentOfPost(postId);
  }
}
