import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  var _cameraController = MobileScannerController(facing: CameraFacing.back);

  String _title = 'CID Holder';
  String? _owner;

  void _onDetect(qrcode, args) {
    if (qrcode.rawValue == null) {
      debugPrint('Failed to scan qrcode');
    } else {
      final String code = qrcode.rawValue!;
      if (code.startsWith('https://certification.canonical.com/hardware/')) {
        var parts = code.split('/');
        setState(() {
          if (_owner == null) {
            _title = 'C3 hardware CID: ${parts[4]}';
          } else {
            _title = 'The CID holder of ${parts[4]} becomes "${_owner}".';
          }
        });
      } else if (!code.isEmpty) {
        setState(() {
          _title = 'QR Code: $code';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_title')),
      body: Form(
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
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Enter your name',
              ),
              onChanged: (String? value) {
                if (value == null || value.isEmpty) {
                  _owner = null;
                } else {
                  _owner = value;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
