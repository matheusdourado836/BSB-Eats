mixin ValidationsMixin {
  String? isEmpty(String? value) {
    if(value!.isEmpty) return 'este campo é obrigatório';
    return null;
  }

  String? emailBadlyFormatted(String? value) {
    if(!value!.contains('@') || !value.contains('.')) return 'formato de email inválido';
    return null;
  }

  String? passwordsDoNotMatch(String? pass1, String? pass2) {
    if(pass1 != pass2) return 'as senhas devem ser iguais';
    return null;
  }

  String? newPassEqualsToOldPass(String? oldPass, String? newPass) {
    if(oldPass == newPass) return 'a senha nova não pode ser igual à antiga';
    return null;
  }

  bool passwordTooShort(String? value) {
    if(value!.length < 6) return true;
    return false;
  }

  bool passwordTooWeak(String? value) {
    RegExp regex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    if(!regex.hasMatch(value!)) return true;
    return false;
  }

  bool passwordHasUppercase(String? value) {
    RegExp regex = RegExp(r'[A-Z]');
    if(!regex.hasMatch(value!)) return true;
    return false;
  }

  bool passwordHasNumber(String? value) {
    RegExp regex = RegExp(r'\d');
    if(!regex.hasMatch(value!)) return true;
    return false;
  }

  String? combine(List<String? Function()> validators) {
    for(final function in validators) {
      final validation = function();
      if(validation != null) return validation;
    }

    return null;
  }

  String? checkPasswordPassesValidation(String? value) {
    List<bool Function()> validators = [
          () => passwordTooShort(value),
          () => passwordTooWeak(value),
          () => passwordHasUppercase(value),
          () => passwordHasNumber(value),
    ];
    for(final function in validators) {
      final validation = function();
      if(validation  == true) {
        return 'A sua senha deve conter:'
            '\n   * Pelo menos 6 digitos;'
            '\n   * Uma letra maiúscula;'
            '\n   * Um caractere especial;'
            '\n   * Um número';
      }
    }

    return null;
  }
}