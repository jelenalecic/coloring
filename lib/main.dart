import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imageLib;

int noOfPixelsPerAxis = 20;

Color abgrToColor(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  int hex = (argbColor & 0xFF00FF00) | (b << 16) | r;
  return Color(hex);
}

List<Color> computeColors(Uint8List bytes) {
  print('computing started');
  List<Color> colors = [];

  List<int> values = bytes.buffer.asUint8List();
  imageLib.Image? image = imageLib.decodeImage(values);

  List<int?> pixels = [];

  int? width = image?.width;
  int? height = image?.height;

  int xChunk = width! ~/ (noOfPixelsPerAxis + 1);
  int yChunk = height! ~/ (noOfPixelsPerAxis + 1);

  for (int j = 1; j < noOfPixelsPerAxis + 1; j++) {
    for (int i = 1; i < noOfPixelsPerAxis + 1; i++) {
      int? pixel = image?.getPixel(xChunk * i, yChunk * j);
      pixels.add(pixel);
      colors.add(abgrToColor(pixel!));
    }
  }

  print('computing ended');
  return colors;
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coloring',
      theme: ThemeData(
        primarySwatch: Colors.grey,

      ),
      home: RootWidget(),
    );
  }
}

class RootWidget extends StatefulWidget {
  const RootWidget({Key? key}) : super(key: key);

  @override
  _RootWidgetState createState() => _RootWidgetState();
}

final String photo =
    'https://iaa-network.com/wp-content/uploads/2021/03/Seychelles-arbitration-1.jpg';

class _RootWidgetState extends State<RootWidget> {
  List<Color?> colors = [];

  @override
  void initState() {
    super.initState();
    extractColors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: UniqueKey(),
      appBar: AppBar(
        title: Text('C o l o r i n g'),
      ),
      body: Container(
        child: Column(
          children: [
            Image.network(photo),
            _getGrid(),
          ],
        ),
      ),
    );
  }

  Future<void> extractColors() async {
    Uint8List bytes = (await NetworkAssetBundle(Uri.parse(photo)).load(photo))
        .buffer
        .asUint8List();
    print('image loaded');

    colors = await compute(computeColors, bytes);
    generatePalette();

    setState(() {});
  }

  Widget _getGrid() {
    return colors.isEmpty
        ? CircularProgressIndicator()
        : GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: noOfPixelsPerAxis),
            itemCount: colors.length,
            itemBuilder: (BuildContext ctx, index) {
              return Container(
                alignment: Alignment.center,
                child: Container(
                  color: colors[index],
                ),
              );
            });
  }

  void generatePalette() {}
}
