import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/restaurant_controller.dart';

class DeleteRestaurantDialog extends StatefulWidget {
  final Restaurante restaurante;
  const DeleteRestaurantDialog({super.key, required this.restaurante});

  @override
  State<DeleteRestaurantDialog> createState() => _DeleteRestaurantDialogState();
}

class _DeleteRestaurantDialogState extends State<DeleteRestaurantDialog> {
  bool _loading = false;

  Future<void> deleteRestaurant() async {
    final restaurantController = Provider.of<RestaurantController>(context, listen: false);
    setState(() => _loading = true);
    final res = await restaurantController.deleteRestaurant(restauranteId: widget.restaurante.id!);
    setState(() => _loading = false);
    Navigator.pop(context, res);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Excluir Restaurante?'),
      content: Text('Você tem certeza que deseja excluir o restaurante "${widget.restaurante.nome ?? 'N/A'}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        if(_loading) const CircularProgressIndicator(strokeWidth: 1.5)
        else
          TextButton(
            onPressed: deleteRestaurant,
            child: const Text('Excluir'),
          )
      ],
    );
  }
}
