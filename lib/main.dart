import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pixel_pvr/app.dart';
import 'package:pixel_pvr/features/vault/data/datasources/documento_local_datasource.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>(DocumentoLocalDataSource.boxName);
  runApp(const PixelPvrApp());
}
