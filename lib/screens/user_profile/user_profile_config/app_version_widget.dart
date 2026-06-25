import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionWidget extends StatelessWidget {
  const AppVersionWidget({super.key});

  Future<PackageInfo> _getAppVersion() async {
    return await PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getAppVersion(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting || snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }else {
          final version = snapshot.data!;
          return Text(
            'Versão: ${version.version}(${snapshot.data!.buildNumber})',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
      }
    );
  }
}