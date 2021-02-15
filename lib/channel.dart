import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct/managed_auth.dart';

import 'azure.dart';
import 'controllers/register.dart';
import 'controllers/tunnel.dart';
import 'kubernetes.dart';
import 'ssh_tunneler.dart';

class MyAppConfiguration extends Configuration {
  MyAppConfiguration(String fileName) : super.fromFile(File(fileName));

  DatabaseConfiguration database;
  AzureConfiguration azure;
}

class SshTunnelerChannel extends ApplicationChannel {
  AuthServer authServer;
  ManagedContext context;
  AzureAuthToken cloudProviderToken;

  @override
  Future prepare() async {
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
    final config = MyAppConfiguration(options.configurationFilePath);

    final context = contextWithConnectionInfo(config.database);
    final delegate = ManagedAuthDelegate<User>(context, tokenLimit: 20);
    authServer = AuthServer(delegate);

    await setupAzure(config.azure);
  }

  Future setupAzure(AzureConfiguration config) async {
    cloudProviderToken = await config.token();
    await config.createResourceGroup();
    try {
      await config.getCluster();
    } on CloudException catch (e) {
      if (e.code == 'ResourceNotFound') {
        await config.createCluster();
      }
    }
    final kube = await Kubernetes.withAzureConfig(config);
    await kube.createDeployment();
  }

  ManagedContext contextWithConnectionInfo(
      DatabaseConfiguration connectionInfo) {
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    final psc = PostgreSQLPersistentStore(
        connectionInfo.username,
        connectionInfo.password,
        connectionInfo.host,
        connectionInfo.port,
        connectionInfo.databaseName);
    context = ManagedContext(dataModel, psc);

    return ManagedContext(dataModel, psc);
  }

  @override
  Controller get entryPoint {
    final router = Router();

    router
        .route('/register')
        .link(() => RegisterController(context, authServer));

    router.route('/auth/token').link(() => AuthController(authServer));

    router
        .route("/tunnel")
        .link(() => Authorizer.bearer(authServer))
        .link(() => TunnelController(cloudProviderToken));

    return router;
  }
}
