import 'dart:convert';
import 'dart:html';
import 'dart:io';

import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_strategy/url_strategy.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

const String LAUNCHPAD_URL = 'https://launchpad.net';
const String GAS_ENDPOINT = 'https://pie.dev/post';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'CID Holder';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CIDHolder(title: _title),
//      debugShowCheckedModeBanner: false,
    );
  }
}

class CIDHolder extends StatefulWidget {
  const CIDHolder({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<CIDHolder> createState() => _CIDHolderState();
}

class _CIDHolderState extends State<CIDHolder> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final _cameraController = MobileScannerController(facing: CameraFacing.back);
  String _title = 'CID Holder';
  late Future<String> _location;
  late Future<List<dynamic>> _locations;
  late Future<String> _owner;
  late Future<String> _oauth_token;
  late Future<String> _oauth_token_secret;
  late Future<bool> _oauth_token_validated;
  final _form = GlobalKey<FormState>();

  Future<List<dynamic>> get_locations(SharedPreferences prefs) async {
    String oauth_consumer_key = "CID Holder (${window.location.href})";
    String oauth_token = prefs.getString('oauth_token') ?? '';
    String oauth_token_secret = prefs.getString('oauth_token_secret') ?? '';
    var now = Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
    var url = Uri.parse(GAS_ENDPOINT +
        "?query=locations&oauth_consumer_key=$oauth_consumer_key&oauth_token=$oauth_token&oauth_token_secret=$oauth_token_secret");
    var res = await http.get(
      url,
      headers: <String, String>{
        'Accept': 'application/json',
      },
    );
    var payload = jsonDecode(res.body);
    return payload;
  }

  void show_me(SharedPreferences prefs) {
    String location = prefs.getString('location') ?? '';
    String oauth_token = prefs.getString('oauth_token') ?? '';
    String oauth_token_secret = prefs.getString('oauth_token_secret') ?? '';
    var now = Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
    var url = Uri.https('api.launchpad.net', 'devel/people/+me');
    http.get(
      url,
      headers: <String, String>{
        'Accept': 'application/json',
        HttpHeaders.authorizationHeader:
            'OAuth realm="https://api.launchpad.net/",' +
                'oauth_consumer_key="CID Holder (${window.location.href})",' +
                'oauth_signature="&${oauth_token_secret}",' +
                'oauth_signature_method="PLAINTEXT",' +
                'oauth_nonce="${now.inSeconds}",' +
                'oauth_timestamp="${now.inSeconds}",' +
                'oauth_token="${oauth_token}",' +
                'oauth_version="1.0"',
      },
    ).then((res) {
      var payload = jsonDecode(res.body);
      var name = payload['name'];
      var disyplay_name = payload['display_name'];
      String owner = '${disyplay_name} (${name})';
      setState(() {
        _owner = prefs.setString('owner', owner).then((bool success) async {
          if (success) {
            if (location.isEmpty) {
              _title = 'CID Holder: ${owner}';
              return owner;
            } else {
              _title = 'CID Holder: ${owner}, Location: ${location}';
              return owner;
            }
          }
          return '';
        });
      });
    });
    return;
  }

  void auth(SharedPreferences prefs) {
    String oauth_token = prefs.getString('oauth_token') ?? '';
    String oauth_token_secret = prefs.getString('oauth_token_secret') ?? '';
    bool oauth_token_validated =
        prefs.getBool('oauth_token_validated') ?? false;
    http
        .post(
      Uri.parse('${LAUNCHPAD_URL}/+access-token'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      encoding: Encoding.getByName('utf-8'),
      body: {
        'oauth_token': oauth_token,
        'oauth_consumer_key': 'CID Holder (${window.location.href})',
        'oauth_signature_method': 'PLAINTEXT',
        'oauth_signature': '&${oauth_token_secret}',
      },
    )
        .then((res) {
      switch (res.body) {
        case 'End-user refused to authorize request token.':
          break;
        case 'Request token has not yet been reviewed. Try again later.':
          break;
        case 'Invalid OAuth signature.':
          break;
        case 'No request token specified.':
          break;
        default:
          final uri =
              Uri.parse('${LAUNCHPAD_URL}/+authorize-token?${res.body}');
          String oauth_token = uri.queryParameters['oauth_token'] ?? '';
          String oauth_token_secret =
              uri.queryParameters['oauth_token_secret'] ?? '';
          String lp_context = uri.queryParameters['lp.context'] ?? '';
          if (oauth_token.isNotEmpty &&
              oauth_token_secret.isNotEmpty &&
              lp_context.isNotEmpty &&
              lp_context == 'None') {
            _oauth_token = prefs
                .setString('oauth_token', oauth_token)
                .then((bool success) async {
              if (success) {
                return oauth_token;
              } else {
                return '';
              }
            });
            _oauth_token_secret = prefs
                .setString('oauth_token_secret', oauth_token_secret)
                .then((bool success) async {
              if (success) {
                return oauth_token_secret;
              } else {
                return '';
              }
            });
            _oauth_token_validated = prefs
                .setBool('oauth_token_validated', true)
                .then((bool success) async {
              return success;
            });
            window.location.reload();
          }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _owner = _prefs.then((SharedPreferences prefs) {
      String owner = prefs.getString('owner') ?? '';
      String oauth_token = prefs.getString('oauth_token') ?? '';
      String oauth_token_secret = prefs.getString('oauth_token_secret') ?? '';
      bool oauth_token_validated =
          prefs.getBool('oauth_token_validated') ?? false;
      if (oauth_token.isNotEmpty && oauth_token_secret.isNotEmpty) {
        if (oauth_token_validated) {
          show_me(prefs);
        } else {
          auth(prefs);
        }
      }
      return owner;
    });
    _location = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('location') ?? '';
    });
    _locations = _prefs.then((SharedPreferences prefs) {
      String oauth_token = prefs.getString('oauth_token') ?? '';
      String oauth_token_secret = prefs.getString('oauth_token_secret') ?? '';
      bool oauth_token_validated =
          prefs.getBool('oauth_token_validated') ?? false;
      if (oauth_token.isNotEmpty &&
          oauth_token_secret.isNotEmpty &&
          oauth_token_validated) {
        return get_locations(prefs);
      }
      return [];
    });
  }

  Future<void> _onDetect(qrcode, args) async {
    final SharedPreferences prefs = await _prefs;
    final String owner = (prefs.getString('owner') ?? '');
    final String oauth_token = (prefs.getString('oauth_token') ?? '');
    final String oauth_token_secret =
        (prefs.getString('oauth_token_secret') ?? '');
    String location = (prefs.getString('location') ?? '');

    if (qrcode.rawValue == null || qrcode.rawValue.isEmpty) {
      return;
    }

    final String code = qrcode.rawValue!;

    if (code.startsWith('https://certification.canonical.com/hardware/') ||
        code.startsWith('https://ubuntu.com/certified/')) {
      var parts = code.split('/');
      var cid = parts[4];

      context.showInfoBar(content: Text('Detected CID: ${cid}'));

      if (owner == null || owner.isEmpty) {
        return;
      }

      var body = {
        'cid': cid,
        'oauth_consumer_key': 'CID Holder (${window.location.href})',
        'oauth_token': oauth_token,
        'oauth_token_secret': oauth_token_secret,
      };

      if (location.isNotEmpty) {
        body['location'] = location;
      }

      var response = http.post(
        Uri.parse(GAS_ENDPOINT),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        encoding: Encoding.getByName('utf-8'),
        body: body,
      );
      response.then((res) {
        if (res.statusCode == 200) {
          if (location.isEmpty) {
            context.showSuccessBar(
                content: Text('The CID holder of ${cid} becomes "${owner}".'));
          } else {
            context.showSuccessBar(
                content: Text(
                    'The CID holder of ${cid} becomes "${owner}" with the location at $location.'));
          }
        } else {
          context.showErrorBar(
              content: Text('Error when changing the CID holder for ${cid}.'));
        }
      });
    } else {
      context.showErrorBar(content: Text('${code}'));
    }
  }

  Future<void> _set_location(String location) async {
    final SharedPreferences prefs = await _prefs;
    String owner = prefs.getString('owner') ?? '';
    _location =
        prefs.setString('location', location).then((bool success) async {
      if (success) {
        setState(() {
          _title = 'CID Holder: ${owner}, Location: ${location}';
        });
        return location;
      }
      return '';
    });
  }

  Future<void> _logout() async {
    _prefs.then((SharedPreferences prefs) {
      _location = prefs.setString('location', '').then((bool success) async {
        return '';
      });
      _owner = prefs.setString('owner', '').then((bool success) async {
        return '';
      });
      _oauth_token =
          prefs.setString('oauth_token', '').then((bool success) async {
        return '';
      });
      _oauth_token_secret =
          prefs.setString('oauth_token_secret', '').then((bool success) async {
        return '';
      });
      _oauth_token_validated = prefs
          .setBool('oauth_token_validated', false)
          .then((bool success) async {
        return false;
      });
      setState(() {
        _title = 'CID Holder';
      });
    });
  }

  Future<void> _login() async {
    final SharedPreferences prefs = await _prefs;
    http
        .post(Uri.parse('${LAUNCHPAD_URL}/+request-token'),
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            encoding: Encoding.getByName('utf-8'),
            body: {
              'oauth_consumer_key': 'CID Holder (${window.location.href})',
              'oauth_signature_method': 'PLAINTEXT',
              'oauth_signature': '&',
            })
        .then((res) {
      final uri = Uri.parse('${LAUNCHPAD_URL}/+authorize-token?${res.body}');
      String oauth_token = uri.queryParameters['oauth_token'] ?? '';
      String oauth_token_secret =
          uri.queryParameters['oauth_token_secret'] ?? '';
      if (oauth_token.isEmpty || oauth_token_secret.isEmpty) {
        return;
      }
      _oauth_token = prefs
          .setString('oauth_token', oauth_token)
          .then((bool success) async {
        if (success) {
          return oauth_token;
        }
        return '';
      });
      _oauth_token_secret = prefs
          .setString('oauth_token_secret', oauth_token_secret)
          .then((bool success) async {
        if (success) {
          return oauth_token_secret;
        }
        return '';
      });
      final auth = Uri.parse(
          '${LAUNCHPAD_URL}/+authorize-token?oauth_token=${oauth_token}&allow_permission=READ_PUBLIC&oauth_callback=${window.location.href}');
      launchUrl(auth, webOnlyWindowName: '_self');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_title'),
        actions: <Widget>[
          FutureBuilder<List<dynamic>>(
            future: _locations,
            builder:
                (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const CircularProgressIndicator();
                default:
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.hasData && snapshot.data!.length > 0) {
                    List<PopupMenuItem<String>> locations = [];
                    snapshot.data!.forEach((location) => locations.add(
                        PopupMenuItem<String>(
                            child: Text(location), value: location)));
                    return PopupMenuButton<String>(
                      itemBuilder: (context) => locations,
                      onSelected: (item) => _set_location(item),
                    );
                  }
                  return Visibility(
                    child: Text("invisible"),
                    visible: false,
                  );
              }
            },
          ),
          FutureBuilder<String>(
            future: _owner,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const CircularProgressIndicator();
                default:
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.hasData && snapshot.data != '') {
                    return IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: _logout,
                    );
                  }
                  return IconButton(
                    icon: Icon(Icons.login),
                    onPressed: _login,
                  );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: MobileScanner(
                  allowDuplicates: false,
                  controller: _cameraController,
                  onDetect: _onDetect),
            ),
          ],
        ),
      ),
    );
  }
}
