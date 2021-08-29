import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:color_manipulations/generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coloring',
      home: RootWidget(),
    );
  }
}

class RootWidget extends StatefulWidget {
  const RootWidget({Key? key}) : super(key: key);

  @override
  _RootWidgetState createState() => _RootWidgetState();
}

final List<Uri> photos = [
  Uri.parse(
      'https://iaa-network.com/wp-content/uploads/2021/03/Seychelles-arbitration-1.jpg'),
  Uri.parse('https://i.imgur.com/bmwGs4n.png'),
  Uri.parse(
      'https://media.tacdn.com/media/attractions-splice-spp-674x446/07/6f/f1/aa.jpg'),
  Uri.parse(
      'https://i.pinimg.com/originals/20/0b/95/200b95dfb2efa80d37479764a324b462.jpg'),
  Uri.parse(
      'https://assets.rappler.co/612F469A6EA84F6BAE882D2B94A4B421/img/CDCC3B2965FC403F94CD4F3B158F1788/image-2019-01-21-3.jpg'),
  Uri.parse('https://cdn.wallpapersafari.com/68/60/HgzJbQ.jpg'),
  Uri.parse('https://wallpaperaccess.com/full/3879268.jpg'),
  Uri.parse('https://wallpapercave.com/wp/wp2461878.jpg'),
  Uri.parse('https://wallpapercave.com/wp/gLCTnod.jpg'),
  Uri.parse(
      'https://c4.wallpaperflare.com/wallpaper/827/998/515/ice-cream-4k-in-hd-quality-wallpaper-preview.jpg'),
  Uri.parse(
      'https://img5.goodfon.com/wallpaper/nbig/e/93/tort-malina-shokolad.jpg'),
];

int photoIndex = 0;
var photo = photos[photoIndex];

int noOfPaletteColors = 4;

class _RootWidgetState extends State<RootWidget> {
  List<Color> colors = [];
  List<Color> sortedColors = [];
  List<Color> palette = [];

  Color primary = Colors.blueGrey;
  Color primaryText = Colors.black;
  Color background = Colors.white;

  late Random random;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    random = Random();
    extractColors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      key: UniqueKey(),
      appBar: AppBar(
        backgroundColor: primary,
        actions: [
          IconButton(
              onPressed: () {
                extractColors();
              },
              icon: const Icon(Icons.refresh))
        ],
        title: Text(
          'Coloring',
          style: TextStyle(color: primaryText, letterSpacing: 1),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: palette.isEmpty
                ? null
                : LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.01, 0.6, 1],
                    colors: [
                      palette.first.withOpacity(0.3),
                      palette[palette.length ~/ 2],
                      palette.last.withOpacity(0.9),
                    ],
                  )),
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              child: imageBytes != null && imageBytes!.isNotEmpty
                  ? Image.memory(
                      imageBytes!,
                      fit: BoxFit.fill,
                    )
                  : const Center(child: CircularProgressIndicator()),
              height: 300,
            ),
            const SizedBox(
              height: 10,
            ),
            _getGrids(),
            Container(
              color: Colors.white.withOpacity(0.5),
              padding: const EdgeInsets.only(top: 6, bottom: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text('Palette of $noOfPaletteColors colors:'),
                  const SizedBox(height: 10),
                  _getPalette()
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> extractColors() async {
    colors = [];
    sortedColors = [];
    palette = [];
    imageBytes = null;

    setState(() {});

    noOfPaletteColors = random.nextInt(4) + 2;
    photoIndex = (photoIndex + 1) % photos.length;
    photo = photos[photoIndex];

    imageBytes =
        (await NetworkAssetBundle(photo).load(photo.path)).buffer.asUint8List();

    colors = await compute(extractPixelsColors, imageBytes);
    setState(() {});
    sortedColors = await compute(sortColors, colors);
    setState(() {});
    palette = await compute(
        generatePalette, {keyPalette: colors, keyNoOfItems: noOfPaletteColors});
    primary = palette.last;
    primaryText = palette.first;
    background = palette.first.withOpacity(0.5);
    setState(() {});
  }

  Widget _getGrids() {
    return SizedBox(
      height: 260,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: colors.isEmpty
                ? Container(
                    child: const CircularProgressIndicator(),
                    alignment: Alignment.center,
                    height: 200,
                  )
                : Column(
                    children: [
                      Text(
                        'Extracted Pixels',
                        style: TextStyle(
                            color:
                                palette.isEmpty ? Colors.black : palette.first),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: noOfPixelsPerAxis),
                          itemCount: colors.length,
                          itemBuilder: (BuildContext ctx, index) {
                            return Container(
                              alignment: Alignment.center,
                              child: Container(
                                color: colors[index],
                              ),
                            );
                          }),
                    ],
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: sortedColors.isEmpty
                ? Container(
                    child: const CircularProgressIndicator(),
                    alignment: Alignment.center,
                    height: 200,
                  )
                : Column(
                    children: [
                      Text(
                        'Sorted Pixels',
                        style: TextStyle(
                            color:
                                palette.isEmpty ? Colors.black : palette.first),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: noOfPixelsPerAxis),
                          itemCount: sortedColors.length,
                          itemBuilder: (BuildContext ctx, index) {
                            return Container(
                              alignment: Alignment.center,
                              child: Container(
                                color: sortedColors[index],
                              ),
                            );
                          }),
                    ],
                  ),
          )
        ],
      ),
    );
  }

  Widget _getPalette() {
    return SizedBox(
      height: 50,
      child: palette.isEmpty
          ? Container(
              child: const CircularProgressIndicator(),
              alignment: Alignment.center,
              height: 100,
            )
          : ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: palette.length,
              itemBuilder: (BuildContext context, int index) => Container(
                color: palette[index],
                height: 50,
                width: 50,
              ),
            ),
    );
  }
}
