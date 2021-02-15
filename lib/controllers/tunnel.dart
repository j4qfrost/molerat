import 'dart:async';

import 'package:ssh_tunneler/azure.dart';

import 'package:aqueduct/aqueduct.dart';

class TunnelController extends ResourceController {
  TunnelController(AzureAuthToken cloudProviderToken) {
    accessToken = cloudProviderToken.tokenString();
  }

  String accessToken;

  @Operation.post()
  Future<Response> createTunnel(@Bind.body() SSHConfig sshConfig) async {
    print('triggered');
    // throw 'test';
    return Response.created('', body: {'url': 'path'});
  }
}

class SSHConfig {
  String pubKey;
  int port = 2222;
}
