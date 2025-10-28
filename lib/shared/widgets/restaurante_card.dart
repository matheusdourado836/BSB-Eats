import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../model/restaurante.dart';

class RestauranteCard extends StatelessWidget {
  final Restaurante restaurante;

  const RestauranteCard({
    super.key,
    required this.restaurante,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Opacity(
        opacity: restaurante.abertoAgora != true ? .6 : 1,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/restaurant_details', arguments: restaurante.id),
          child: Card(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    if(restaurante.image != null)
                      CachedNetworkImage(
                        imageUrl: restaurante.image!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Chip(
                        label: restaurante.abertoAgora != true
                          ? const Text('Fechado')
                          : const Text('Aberto'),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        backgroundColor: restaurante.abertoAgora != true ? Colors.red : Colors.green,
                      )
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.yellow, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              restaurante.avaliacao?.toStringAsFixed(1) ?? '0.0',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurante.nome ?? 'sem nome',
                        style: Theme.of(context).textTheme.labelLarge
                      ),
                      const SizedBox(height: 6),
                      Text(restaurante.categoria?.description ?? 'sem categoria',
                        style: Theme.of(context).textTheme.labelMedium
                      ),
                      const SizedBox(height: 16),
                      Row(
                        spacing: 2,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: Theme.of(context).textTheme.labelMedium?.color
                          ),
                          Expanded(
                            child: Text(
                              restaurante.endereco ?? 'sem endereço',
                              style: Theme.of(context).textTheme.labelMedium
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/restaurant_details', arguments: restaurante.id),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                          label: const Text("Detalhes"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}