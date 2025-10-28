String dayInPortuguese(String day) {
  switch (day.toLowerCase()) {
    case "monday":
      return "Segunda-feira";
    case "tuesday":
      return "Terça-feira";
    case "wednesday":
      return "Quarta-feira";
    case "thursday":
      return "Quinta-feira";
    case "friday":
      return "Sexta-feira";
    case "saturday":
      return "Sábado";
    case "sunday":
      return "Domingo";
    default:
      return day;
  }
}