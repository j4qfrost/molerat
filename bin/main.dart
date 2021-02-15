import 'package:ssh_tunneler/ssh_tunneler.dart';

Future main() async {
  final app = Application<SshTunnelerChannel>()
    ..options.configurationFilePath = "config.yaml"
    ..options.port = 8888
    ..isolateStartupTimeout = Duration(minutes: 5);

  final count = Platform.numberOfProcessors ~/ 2;
  await app.start(numberOfInstances: count > 0 ? count : 1);

  print("Application started on port: ${app.options.port}.");
  print("Use Ctrl-C (SIGINT) to stop running the application.");
}
