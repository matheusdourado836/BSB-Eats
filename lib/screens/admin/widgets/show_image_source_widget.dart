import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/social_media_controller.dart';
import '../../../shared/widgets/image_picker.dart';

Future<dynamic> showImageSourceBottomSheet(BuildContext context) async {
  return await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Escolher da galeria'),
              onTap: () => pickSingleFile(context).then((res) {
                if(res is File) {
                  Navigator.pop(context, res);
                }
              }),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher do banco de imagens'),
              onTap: () async {
                final res = await showCommonImagesDialog(context);
                Navigator.pop(context, res);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<dynamic> showCommonImagesDialog(BuildContext context) async {
  final socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  return await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: FutureBuilder<List<String>>(
          future: socialMediaController.getCommonImages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Erro ao carregar imagens: ${snapshot.error}'),
              );
            }

            final images = snapshot.data ?? [];
            if (images.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma imagem disponível.'),
              );
            }

            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 400,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageUrl = images[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    },
  );
}