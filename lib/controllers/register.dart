import 'dart:async';

import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct/managed_auth.dart';

class User extends ManagedObject<_User>
    implements _User, ManagedAuthResourceOwner<_User> {
  @Serialize(input: true, output: false)
  String password;
}

class _User extends ResourceOwnerTableDefinition {
  @Column(unique: true)
  String email;
}

class RegisterController extends ResourceController {
  RegisterController(this.context, this.authServer);

  final ManagedContext context;
  final AuthServer authServer;

  @Operation.post()
  Future<Response> createUser(@Bind.body() User user) async {
    // Check for required parameters before we spend time hashing
    if (user.username == null || user.password == null) {
      return Response.badRequest(
          body: {'error': 'username and password required.'});
    }
    print('test');
    user
      ..salt = AuthUtility.generateRandomSalt()
      ..hashedPassword = authServer.hashPassword(user.password, user.salt);
    print('test');

    return Response.ok(await Query(context, values: user).insert());
  }
}
