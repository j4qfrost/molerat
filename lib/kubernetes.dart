import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ssh_tunneler/azure.dart';

class Kubernetes {
  Kubernetes(this.bearerToken, this.clusterURL);
  String bearerToken;
  String clusterURL = 'https://localhost';

  static Future<Kubernetes> withAzureConfig(AzureConfiguration config) async {
    final token = await config.fetchClusterToken();
    return Kubernetes(token, config.clusterURL);
  }

  Future<dynamic> sendRequest(String method, String url,
      {Map<String, String> headers, dynamic body}) async {
    final request = http.Request(method, Uri.parse(url));
    request.headers.addAll(headers);
    if (body != null) {
      if (headers['Content-Type'] == 'application/x-www-form-urlencoded') {
        request.bodyFields = body as Map<String, String>;
      } else {
        request.body = jsonEncode(body);
      }
    }

    final http.StreamedResponse response = await request.send();

    if (response.statusCode >= 200 && response.statusCode < 400) {
      return jsonDecode(await response.stream.bytesToString());
    } else {
      print(StackTrace.current);
      throw await response.stream.bytesToString();
    }
  }

  Future<dynamic> createDeployment() async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': bearerToken,
    };

    // TODO yaml and generalize
    final body = {
      "apiVersion": "apps/v1",
      "kind": "Deployment",
      "metadata": {
        "name": "nginx-deployment",
        "labels": {"app": "nginx"}
      },
      "spec": {
        "replicas": 3,
        "selector": {
          "matchLabels": {"app": "nginx"}
        },
        "template": {
          "metadata": {
            "labels": {"app": "nginx"}
          },
          "spec": {
            "containers": [
              {
                "name": "nginx",
                "image": "nginx:1.14.2",
                "ports": [
                  {"containerPort": 80}
                ]
              }
            ]
          }
        }
      }
    };
    final response = await sendRequest(
      'POST',
      '$clusterURL/apis/apps/v1/namespaces/default/deployments',
      headers: headers,
      body: body,
    );

    print(response);
  }
}
