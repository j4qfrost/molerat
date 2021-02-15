import 'dart:async';
import 'dart:convert';

import 'package:aqueduct/aqueduct.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

class AzureAuthToken {
  AzureAuthToken(dynamic authObject) {
    tokenType = authObject['token_type'] as String;
    expiresIn = int.parse(authObject['expires_in'] as String);
    expiresOn = DateTime(int.parse(authObject['expires_on'] as String));
    accessToken = authObject['access_token'] as String;
  }

  String tokenType;
  int expiresIn;
  DateTime expiresOn;
  String accessToken;

  String tokenString() {
    return '$tokenType $accessToken';
  }
}

class CloudException implements Exception {
  CloudException(this.code, this.message);

  String code;
  String message;
}

class AzureConfiguration extends Configuration {
  String tenantId;
  String clientId;
  String clientSecret;
  String subscriptionId;
  String resource;
  String resourceGroup;
  String clusterName;
  String clusterURL;

  static AzureAuthToken _token;

  Future<AzureAuthToken> token() async {
    if (_token != null) {
      final now = DateTime.now();
      if (now.isAfter(_token.expiresOn)) {
        return _token;
      }
    }

    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = {
      'grant_type': 'client_credentials',
      'client_id': clientId,
      'client_secret': clientSecret,
      'resource': resource,
    };
    final response = await sendRequest(
      'POST',
      'https://login.microsoftonline.com/${tenantId}/oauth2/token',
      headers: headers,
      body: body,
    );

    return _token = AzureAuthToken(response);
  }

  // async sendRequest(String url)

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
      final errorBody = jsonDecode(await response.stream.bytesToString());
      throw CloudException(
          errorBody['code'] as String, errorBody['message'] as String);
    }
  }

  Future<dynamic> listClusterResourceCredentials() async {
    final headers = {
      'Authorization': _token.tokenString(),
    };

    return await sendRequest(
      'POST',
      'https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/$clusterName/listClusterAdminCredential?api-version=2020-11-01',
      headers: headers,
    );
  }

  Future createResourceGroup() async {
    final headers = {
      'Authorization': _token.tokenString(),
      'Content-Type': 'application/json'
    };
    final body = {
      'location': 'westus',
    };
    await sendRequest(
      'PUT',
      'https://management.azure.com/subscriptions/$subscriptionId/resourcegroups/$resourceGroup?api-version=2020-06-01',
      headers: headers,
      body: body,
    );
  }

  Future<dynamic> getCluster() async {
    final headers = {
      'Authorization': _token.tokenString(),
    };
    return await sendRequest(
      'GET',
      'https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/$clusterName?api-version=2020-11-01',
      headers: headers,
    );
  }

  Future createCluster() async {
    final headers = {
      'Authorization': _token.tokenString(),
      'Content-Type': 'application/json'
    };
    final body = {
      'location': 'westus',
      'properties': {
        'agentPoolProfiles': [
          {
            'name': 'nodepool1',
            'vmSize': 'Standard_DS2_v2',
            'count': 2,
            'mode': 'System'
          }
        ],
        'dnsPrefix': 'tunnelercluster',
        'servicePrincipalProfile': {
          'clientId': clientId,
          'secret': clientSecret
        }
      },
    };
    await sendRequest(
      'PUT',
      'https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/$clusterName?api-version=2020-11-01',
      headers: headers,
      body: body,
    );
  }

  Future<String> fetchClusterToken() async {
    final credentialsList = await listClusterResourceCredentials();
    final kubeconfigs = credentialsList['kubeconfigs'];
    final adminCredentials = loadYaml(String.fromCharCodes(
        base64Decode(kubeconfigs[0]['value'] as String)))['users'][0]['user'];
    return 'Bearer ${adminCredentials['token'] as String}';
  }
}
