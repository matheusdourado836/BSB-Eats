import 'dart:developer';
import 'dart:math' hide log;
import 'package:bsb_eats/service/firebase_messaging_service.dart';
import 'package:bsb_eats/service/social_media_service.dart';
import 'package:bsb_eats/service/user_service.dart';
import 'package:bsb_eats/shared/model/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../shared/model/user.dart';
import 'dio_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseMessagingService _messaging = FirebaseMessagingService();
  static final SocialMediaService _socialMediaService = SocialMediaService();
  static final UserService _userService = UserService();
  static final _gAuth = GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<MyUser?> getLoggedUser() async {
    MyUser? user;
    // final dio = Dio();
    // final response = await dio.post(
    //   'https://www.nylus.space/app/create-prompt',
    //   data: [{"appName":"Pizzaria do Zé","appFunction":"Disponibilizar um cardápio digital visualmente atraente onde clientes podem personalizar seus hambúrgueres em um fluxo passo a passo (pão, tipo/ponto da carne, queijo, remover ingredientes, adicionais), montar combos (com batata e bebida), usar cupons e fazer pedidos para delivery (com taxa por CEP/bairro) ou retirada. O pagamento deve ser integrado (Cartão, Pix, dinheiro com troco).","targetAudience":"Donos de hamburguerias artesanais que buscam oferecer uma experiência de pedido premium, se diferenciar da concorrência e aumentar o ticket médio através de um aplicativo próprio, com personalização completa dos lanches.","purposeBeforeAfter":"Aumentar o ticket médio com a venda de adicionais e combos, agilizar o fluxo de pedidos na cozinha com comandas detalhadas, fortalecer a marca com um app próprio e criar um relacionamento direto com os clientes. O painel admin permitirá ver estatísticas de vendas e os produtos mais vendidos, além de gerenciar o horário de funcionamento e um modo 'alta demanda' com taxas dinâmicas.","whoWillUse":"Clientes para montar seus lanches e fazer pedidos; o time da cozinha para receber os pedidos detalhados em um painel; o gerente para atualizar o cardápio, promoções e analisar as estatísticas de venda no painel de administrador.","mainMenu":"Cardápio (com categorias: Artesanais, Smash, Combos), Tela de Monte seu Lanche (passo a passo), Carrinho de Compras, Checkout (com endereço e pagamento), Status do Pedido (com notificações), Perfil do Cliente (com histórico e favoritos), Painel de Administrador (gestão de produtos, pedidos, estatísticas).","additionalFeatures":"","appLanguage":"Português","font":"Roboto","targetAI":"Lovable","complementaryFeatures":["Design 100% Responsivo"],"primaryColor":"#8000FF","secondaryColor":"#1F1F1F","backgroundColor":"#171717","foregroundColor":"#FFFFFF"}]
    // );
    // log('OLHA A RESPONSE AEEEEEE $response');
    if(_auth.currentUser == null) {
      return null;
    }
    await _database.collection("users").doc(_auth.currentUser?.uid ?? "").get().then((DocumentSnapshot doc) async {
      if(doc.exists) {
        final dbUser = doc.data() as Map<String, dynamic>;
        user = MyUser.fromJson(dbUser);
        user?.emailVerified = _auth.currentUser?.emailVerified;
        if(user?.emailVerified != true) return;
        user?.providers ??= [];
        user?.providers = _getUserProviders();
        final token = await _setUserToken();
        user?.fcmToken = token;
        user?.likes ??= [];
        final likesSnapshot = await _database.collection('users').doc(user?.id).collection('likes').get();
        user?.likes = likesSnapshot.docs.map((doc) => Like.fromJson(doc.data())).toList();
      }
    });

    return user;
  }

  List<String> _getUserProviders() {
    final user = _auth.currentUser;
    if(user != null) {
      final providerIds = user.providerData.map((p) => p.providerId).toList();
      return providerIds;
    }

    return [];
  }

  Future<String?> _setUserToken() async {
    try{
      final token = await _messaging.getToken();
      await _userService.updateUserData({"fcmToken": token});
      return token;
    }catch(_) {
      return null;
    }
  }

  Future<UserCredential?> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> registerUser({required MyUser user, required String pass}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: user.email!, password: pass);
    if(credential.user != null) {
      await _auth.currentUser!.updateDisplayName(user.nome);
      user.id = credential.user!.uid;
      await saveUserData(user);
      sendEmailVerification();
      return credential;
    }

    return null;
  }

  Future<void> sendEmailVerification() async => _auth.currentUser?.sendEmailVerification();

  Future<void> resetPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }

  Future<User?> reloadUser() async {
    await _auth.currentUser!.reload();
    return _auth.currentUser;
  }

  Future<UserCredential?> reauthenticateUser(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if(userCredential.credential != null) {
      return await reauthenticateWithCredential(userCredential.credential!);
    }

    return null;
  }

  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    return await _auth.currentUser!.reauthenticateWithCredential(credential);
  }

  Future<void> updatePassword(String newPassword) async {
    return await _auth.currentUser!.updatePassword(newPassword);
  }

  Future<void> deleteAccount(MyUser user) async {
    try{
      final userId = _auth.currentUser!.uid;
      final userPostsSnapshot = await _database.collection('posts').where('authorID', isEqualTo: userId).get();
      final userPosts = userPostsSnapshot.docs.map((doc) => Post.fromJson(doc.data())).toList();
      final files = await _storage.ref().child('users/$userId').listAll();
      await Future.wait(files.items.map((file) => file.delete()));
      await Future.wait(userPosts.map((p) => _socialMediaService.deletePost(post: p)));
      await _database.collection('usernames').doc(user.username).delete();
      await _database.collection('users').doc(userId).delete();
      await _auth.currentUser!.delete();
      return;
    }on FirebaseException catch(e) {
      print('ERRO FIREBASE AUTH $e');
      return;
    }catch(e) {
      print('ERRO DESCONHECIDO AO DELETAR CONTA $e');
      rethrow;
    }
  }

  Future<void> saveUserData(MyUser user) async {
    await saveWithTransaction(user);
    if(user.profilePhotoUrl?.isNotEmpty ?? false) {
      final photoURL = await _userService.updateUserProfilePicture(user);
      _auth.currentUser!.updatePhotoURL(photoURL);
    }
    return;
  }

  Future<bool> saveWithTransaction(MyUser user) async {
    final usersRef = _database.collection('users').doc(user.id);
    final username = (user.username ?? await generateUniqueUsername(user.nome!)).toLowerCase().trim();
    final usernameRef = _database.collection('usernames').doc(username);

    final success = await _database.runTransaction<bool>((transaction) async {
      // 1) Verifica se o username já foi reservado
      final usernameDoc = await transaction.get(usernameRef);
      if (usernameDoc.exists) {
        return false; // já em uso
      }

      // 2) Reserva o username
      transaction.set(usernameRef, {
        'uid': user.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3) Cria/atualiza o usuário no id = uid
      final jsonUser = user.toJson()
        ..['username'] = username
        ..['createdAt'] = FieldValue.serverTimestamp();

      transaction.set(usersRef, jsonUser);

      return true;
    });

    return success;
  }

  Future<String> generateUniqueUsername(String displayName) async {
    String baseUsername = displayName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

    String candidate = '';
    bool exists = true;
    final random = Random();

    while (exists) {
      // Gera um número aleatório de 3 dígitos (100–999)
      int randomNumber = 100 + random.nextInt(900);
      candidate = "$baseUsername$randomNumber";

      // Verifica se já existe no Firestore
      final doc = await _database.collection('usernames').doc(candidate).get();
      exists = doc.exists;
    }

    return candidate;
  }

  Future<UserCredential?> signInWithCredential(AuthCredential credential) async {
    try{
      final userCredential = await _auth.signInWithCredential(credential);
      if(userCredential.user != null) {
        if(!await checkIfUserAlreadyExists()) {
          final user = userCredential.user!;
          final name = user.displayName ?? user.email?.split('@')[0] ?? '';
          final username = await generateUniqueUsername(name);
          final userModel = MyUser(
            nome: user.displayName,
            username: username,
            email: user.email,
            profilePhotoUrl: user.photoURL,
          );
          final jsonUser = userModel.toJson();
          jsonUser["id"] = user.uid;
          jsonUser["createdAt"] = FieldValue.serverTimestamp();
          await _database.collection("users").doc(user.uid).set(jsonUser);
        }
      }
      return userCredential;
    }catch(e) {
      return null;
    }
  }

  Future<OAuthCredential?> getGoogleCredential() async {
    try {
      final GoogleSignInAccount gUser = await _gAuth.authenticate();

      final GoogleSignInAuthentication gAuth = gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
      );
      return credential;
    }on GoogleSignInException catch(_) {}

    return null;
  }

  Future<OAuthCredential> getAppleCredential() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ]);

    final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode
    );

    return oAuthCredential;
  }

  Future<bool> checkIfUserAlreadyExists() async {
    final user = await _database.collection('users').doc(_auth.currentUser?.uid).get();
    return user.exists;
  }

  Future<bool> isUsernameAvailable(String username) async {
    final snapshot = await _database
        .collection('usernames')
        .get();

    return snapshot.docs.where((doc) => doc.id == username.toLowerCase()).isEmpty;
  }

  Future<void> logout() async {
    _userService.updateUserData({"fcmToken": null});
    await _auth.signOut();
    await _gAuth.signOut();
    await _gAuth.disconnect();
    await _messaging.deleteToken();
  }

  void changeApiUrl(String url) => DioClient().updateBaseUrl(url);
}