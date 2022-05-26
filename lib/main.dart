import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flash/flash.dart';

void main() => runApp(const MyApp());

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
  late Future<String> _owner;
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _owner = _prefs.then((SharedPreferences prefs) {
      String owner = prefs.getString('owner') ?? '';
      if (owner.isNotEmpty) {
        setState(() {
          _title = 'CID Holder: ${owner}';
        });
      }
      return owner;
    });
  }

  Future<void> _onDetect(qrcode, args) async {
    final SharedPreferences prefs = await _prefs;
    final String owner = (prefs.getString('owner') ?? '');

    if (qrcode.rawValue == null || qrcode.rawValue.isEmpty) {
      return;
    }

    final String code = qrcode.rawValue!;

    if (code.startsWith('https://certification.canonical.com/hardware/')
        || code.startsWith('https://ubuntu.com/certified/')) {
      var parts = code.split('/');
      var cid = parts[4];
      if (owner == null || owner.isEmpty) {
        context.showInfoBar(content: Text('C3 hardware CID: ${cid}'));
      } else {
        var response = http.post(
          Uri.parse('https://pie.dev/post'),
          headers: <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          encoding: Encoding.getByName('utf-8'),
          body: {'cid': cid, 'name': owner},
        );
        response.then((res) {
          if (res.statusCode == 200) {
            context.showSuccessBar(content: Text('The CID holder of ${cid} becomes "${owner}".'));
          } else {
            context.showErrorBar(content: Text('Error when changing the CID holder for ${cid}.'));
          }
        });
      }
    } else {
      context.showErrorBar(content: Text('${code}'));
    }
  }

  Future<void> _showInputFlash({
    bool persistent = true,
    WillPopCallback? onWillPop,
    Color? barrierColor,
  }) async {
    final SharedPreferences prefs = await _prefs;
    var editingController = TextEditingController();
    context.showFlashBar(
        persistent: persistent,
        onWillPop: onWillPop,
        barrierColor: barrierColor,
        borderWidth: 3,
        behavior: FlashBehavior.fixed,
        forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
        title: Text('Please input your name'),
        content: Form(
            child: TextFormField(
                controller: editingController,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'CID holder will become your name when it detects the QR codes of CID.',
                    hintStyle: TextStyle(color: Colors.grey),
                ),
            ),
        ),
        primaryActionBuilder: (context, controller, _) {
          return IconButton(
              onPressed: () {
                controller.dismiss();
                String owner = '';
                if (editingController.text.isNotEmpty) {
                  owner = editingController.text;
                }
                setState(() {
                  _owner = prefs.setString('owner', owner).then((bool success) {
                    if (success) {
                      if (owner.isNotEmpty) {
                        _title = 'CID Holder: ${owner}';
                      } else {
                        _title = 'CID Holder';
                      }
                    }
                    return owner;
                  });
                });
              },
              icon: Icon(Icons.save),
              );
        },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_title'),
        actions: <Widget>[
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
                    if (snapshot.data != null && snapshot.data != '') {
                      return IconButton(
                          icon: Icon(Icons.logout),
                          onPressed: () {
                            _showInputFlash(barrierColor: Colors.black54);
                          }
                      );
                    }
                    return IconButton(
                        icon: Icon(Icons.login),
                        onPressed: () {
                          _showInputFlash(barrierColor: Colors.black54);
                        }
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
                onDetect: _onDetect
              ),
            ),
          ],
        ),
      ),
    );
  }
}
