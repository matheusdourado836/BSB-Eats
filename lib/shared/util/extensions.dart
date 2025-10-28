import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../model/weekday.dart';

Future<ShareResultStatus> share({required String text, String? title}) async {
  final res = await SharePlus.instance.share(
      ShareParams(
          text: text,
          title: title,
          previewThumbnail: XFile('assets/images/logo_alt.png')
      )
  );
  return res.status;
}

extension WidgetStateUtils on State {
  AssetBundle assetBundle() {
    return DefaultAssetBundle.of(context);
  }

  ThemeData theme() {
    return Theme.of(context);
  }

  MediaQueryData mediaQuery() {
    return MediaQuery.of(context);
  }

  void showCustomSnackBar({int? seconds, required Widget child}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(seconds: seconds ?? 4),
      elevation: 4,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(16),
      behavior: SnackBarBehavior.floating,
      content: child,
    ));
  }

  void showCustomTopSnackBar({int? seconds, required String text}) {
    Widget snackBarResult() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
            borderRadius: BorderRadiusDirectional.circular(12),
            color: const Color(0xff2E322C)
        ),
        child: Text(text, style: theme().textTheme.labelSmall),
      );
    }

    showTopSnackBar(
        Overlay.of(context),
        displayDuration: Duration(seconds: seconds ?? 3),
        snackBarResult()
    );
  }
}

extension FirebaseTranslator on FirebaseAuthException {
  String translated() {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta. Por favor, tente novamente.';
      case 'email-already-in-use':
        return 'Este e-mail já está sendo usado.';
      case 'invalid-email':
        return 'E-mail inválido. Por favor, insira um e-mail válido.';
      case 'invalid-email-verified':
        return 'E-mail não verificado. Por favor, verifique seu e-mail.';
      case 'invalid-credential':
        return 'As credenciais fornecidas estão incorretas ou expiraram.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return 'Ocorreu um erro inesperado. Tente novamente mais tarde.';
    }
  }
}

extension BrFormat on DateTime {

  String formatted({bool includeTime = false}) {
    return '${day < 10 ? '0$day' : day}/${month < 10 ? '0$month' : month}/$year ${includeTime ? '${hour > 9 ? hour : '0$hour'}h ${minute > 9 ? minute : '0$minute'}m' : ''}'.trim();
  }


  String toIso8601DateOnly() {
    return toIso8601String().split('T').first;
  }

  String toFriendlyDate() {
    final now = DateTime.now();
    final difference = now.difference(this);

    // Hoje -> em horas
    if (difference.inDays == 0) {
      if (difference.inHours > 0) {
        final hours = difference.inHours == 1 ? 'hora' : 'horas';
        return "Há ${difference.inHours} $hours";
      }else if(difference.inSeconds < 60) {
        return 'Agora';
      }else {
        final minutes = difference.inMinutes == 1 ? 'minuto' : 'minutos';
        return "Há ${difference.inMinutes} $minutes";
      }
    }

    // Até 7 dias atrás
    if (difference.inDays <= 7) {
      final days = difference.inDays == 1 ? 'dia' : 'dias';
      return "Há ${difference.inDays} $days";
    }

    // Mesmo ano
    if (year == now.year) {
      return "$day de ${_monthName(month)}";
    }

    // Ano anterior ou mais antigo
    return "$day de ${_monthName(month)} de $year";
  }

  String toCommentDate() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Há $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Há $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return 'Há $days ${days == 1 ? 'dia' : 'dias'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Há $months ${months == 1 ? 'mês' : 'meses'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Há $years ${years == 1 ? 'ano' : 'anos'}';
    }
  }

  String _monthName(int month) {
    const months = [
      "janeiro",
      "fevereiro",
      "março",
      "abril",
      "maio",
      "junho",
      "julho",
      "agosto",
      "setembro",
      "outubro",
      "novembro",
      "dezembro"
    ];
    return months[month - 1];
  }

}

extension Initials on String {

  String initials() {
    if (contains(' ')) {
      final parts = trim().split(' ');
      final first = parts.first.characters.first.toUpperCase();
      final second = parts.last.characters.first.toUpperCase();
      return '$first$second';
    }else {
      final first = characters.first.toUpperCase();
      final second = characters.elementAt(1).toUpperCase();
      return '$first$second';
    }
  }

  String obscured() {
    final emailPart1 = split('@')[0];
    final userEmail = emailPart1.substring(0, (emailPart1.length / 2).round() - 1);
    final rest = List<String>.generate(emailPart1.length - (emailPart1.length / 2).round() + 1, (index) => '*').toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '');
    final provedor = split('@')[1];
    final provedorPart1 = provedor.split('.')[0];
    final provedorRest = List<String>.generate(provedorPart1.length - 2, (index) => '*').toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '');
    final userFormatted = '$userEmail$rest@${provedorPart1.substring(0, 2)}$provedorRest.${provedor.split('.')[1]}';

    return userFormatted;
  }

}

extension TextFormatted on String {
  String removerAcentos() {
    const acentos = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ū': 'u',
      'ç': 'c',
      'Á': 'A',
      'À': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Í': 'I',
      'Ì': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ó': 'O',
      'Ò': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ú': 'U',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ç': 'C'
    };

    String textoSemAcentos = this;
    acentos.forEach((acento, semAcento) {
      textoSemAcentos = textoSemAcentos.replaceAll(acento, semAcento);
    });

    return textoSemAcentos;
  }

  String translated() {
    switch (this) {
      case 'monday': return 'Segunda-feira';
      case 'tuesday': return 'Terça-feira';
      case 'wednesday': return 'Quarta-feira';
      case 'thursday': return 'Quinta-feira';
      case 'friday': return 'Sexta-feira';
      case 'saturday': return 'Sábado';
      case 'sunday': return 'Domingo';
      default: return this;
    }
  }
}

/// Extensão de conveniência para texto de status
extension WeeklyOpeningHoursX on WeeklyOpeningHours {
  String statusLabel({DateTime? moment}) => isOpenNow(moment: moment) ? 'Aberto agora' : 'Fechado agora';
}

extension DateParser on CurrentOpeningHours {
  Map<String, String> get _diasSemana => {
    "Monday": "Segunda-feira",
    "Tuesday": "Terça-feira",
    "Wednesday": "Quarta-feira",
    "Thursday": "Quinta-feira",
    "Friday": "Sexta-feira",
    "Saturday": "Sábado",
    "Sunday": "Domingo",
  };

  String _formatarHorario(String horario) {
    if(horario.contains('24 horas') || horario.toLowerCase().contains('fechado')) return horario;
    final isPM = horario.contains("PM");
    final isAM = horario.contains("AM");

    var partes = horario.replaceAll("AM", "").replaceAll("PM", "").trim().split(":");
    int horas = int.parse(partes[0]);
    String minutos = partes.length > 1 ? partes[1] : "00";

    if (isPM && horas != 12) horas += 12;
    if (isAM && horas == 12) horas = 0;

    return "${horas.toString().padLeft(2, '0')}:$minutos";
  }

  List<Map<String, dynamic>> parseHorario() {
    List<Map<String, dynamic>> times = [];
    for(final time in weekdayDescriptions ?? []) {
      final partes = time.split(": ");
      final dia = _diasSemana[partes[0]] ?? partes[0].toString().translated();
      final horarios = partes[1].split(", ").map((h) {
        if(h == 'Closed') return 'Fechado';
        final intervalo = h.split("–").map((p) => _formatarHorario(p.trim())).toList();
        if(intervalo.length == 1) return intervalo[0];
        return "${intervalo[0]} - ${intervalo[1]}";
      }).toList();

      times.add({
        "dia": dia,
        "horarios": horarios,
      });
    }
    return times;
  }

  List<String> getTodayDate() {
    final now = DateTime.now().weekday;
    final times = parseHorario();
    final timesList = List<String>.from(times[now - 1]["horarios"]);

    return timesList.map((t) => t.replaceAll('-', 'às')).toList();
  }
}

extension QuantityFormatter on String {
  String toFriendlyQuantity() {
    int info = int.parse(this);
    String infoString = info.toString();
    if(info <= 9999) {
      return infoString;
    }else if(info <= 99999) {
      return '${infoString.substring(0, 2)}.${infoString[3]}k';
    }else if(info <= 999999) {
      return '${infoString.substring(0, 3)}k';
    }else {
      return '${infoString.substring(0, 3)}mi';
    }
  }
}