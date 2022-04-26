import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CID Holder',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CIDHolder(title: 'CID Holder'),
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
  MobileScannerController cameraController = MobileScannerController();
  var appBarTitleText = Text('CID Holder');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: appBarTitleText),
      body: MobileScanner(
          allowDuplicates: false,
          controller: MobileScannerController(
            facing: CameraFacing.back, torchEnabled: true),
          onDetect: (qrcode, args) {
            if (qrcode.rawValue == null) {
              debugPrint('Failed to scan qrcode');
            } else {
              final String code = qrcode.rawValue!;
              if (code.startsWith('https://certification.canonical.com/hardware/')) {
                var parts = code.split('/');
                debugPrint('CID found! ${parts[4]}');
                setState(() {
                  appBarTitleText = Text('CID Holder ${parts[4]}');
                });
              } else {
                debugPrint('qrcode found! $code');
              }
            }
          }),
    );
  }
}
