import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      return prefs.getString('owner') ?? '';
    });
  }

  Future<void> _onDetect(qrcode, args) async {
    final SharedPreferences prefs = await _prefs;
    final String owner = (prefs.getString('owner') ?? '');
//    debugPrint('Get owner ${owner}');

    if (qrcode.rawValue == null) {
      debugPrint('Failed to scan qrcode');
    } else {
      final String code = qrcode.rawValue!;
      if (code.startsWith('https://certification.canonical.com/hardware/')
          || code.startsWith('https://ubuntu.com/certified/')) {
        var parts = code.split('/');
        var cid = parts[4];
        if (owner == null || owner.isEmpty) {
          setState(() {
            _title = 'C3 hardware CID: ${cid}';
          });
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
              setState(() {
                _title = 'The CID holder of ${cid} becomes "${owner}".';
              });
            } else {
              setState(() {
                _title = 'Error when changing the CID holder for ${cid}.';
              });
            }
          });
        }
      } else if (!code.isEmpty) {
        setState(() {
          _title = 'QR Code: $code';
        });
      }
    }
  }

  Future<void> _onSaved(String? owner) async {
    final SharedPreferences prefs = await _prefs;
    if (owner == null) {
      owner = '';
    }
    setState(() {
      _owner = prefs.setString('owner', owner!).then((bool success) {
//        debugPrint('Set owner ${owner} ${success}');
        return owner!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_title'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              _form.currentState?.save();
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
            Form(
              key: _form,
              child: FutureBuilder<String>(
                future: _owner,
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return const CircularProgressIndicator();
                    default:
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
//                      debugPrint('Initialize owner ${snapshot.data}');
                      return TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                        ),
                        initialValue: snapshot.data,
                        onSaved: _onSaved,
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
