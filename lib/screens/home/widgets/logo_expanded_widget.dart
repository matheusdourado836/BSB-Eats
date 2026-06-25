import 'package:bsb_eats/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoExpandedWidget extends StatefulWidget {
  const LogoExpandedWidget({super.key});

  @override
  State<LogoExpandedWidget> createState() => _LogoExpandedWidgetState();
}

class _LogoExpandedWidgetState extends State<LogoExpandedWidget> {
  bool _animate = false;
  int _count = 0;

  Future<void> _savePoints() async {
    final userController = Provider.of<UserController>(context, listen: false);
    int userPoints = userController.currentUser?.pontos ?? 0;
    final prefs = await SharedPreferences.getInstance();
    if(!prefs.containsKey('hasEarnedPoints')) {
      prefs.setBool('hasEarnedPoints', true);
      userPoints += 10;
      userController.updateUserData({"pontos": userPoints});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: const Color(0xff183A13),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => setState(() {
                  _animate = !_animate;
                  if(_count < 10) {
                    _count++;
                  }if(_count == 10) {
                    _savePoints();
                  }
                }),
                splashColor: Colors.transparent,
                radius: 0,
                child: Image.asset('assets/images/logo_alt.png')
                  .animate(target: _animate ? 1 : 0)
                  .flipH(begin: 1, duration: 700.ms)
                  .flipH(begin: 1, duration: 700.ms)
              ),
              Text(
                'BSB Eats',
                style: GoogleFonts.mynerve(
                  textStyle: const TextStyle(
                    fontSize: 48,
                    color: Color(0xFFE6DDAF),
                  ),
                )
              ),
              const SizedBox(height: 8),
              Text(
                'Brasília na palma da mão',
                textAlign: TextAlign.center,
                style: GoogleFonts.mynerve(
                  textStyle: const TextStyle(
                    fontSize: 38,
                    color: Color(0xFFE6DDAF),
                  )
                )
              ),
              const SizedBox(height: 56),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  fixedSize: const Size(150, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)
                  )
                ),
                child: const Text('Voltar')
              ),
              const Spacer(),
              Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    width: 30,
                    height: 30,
                    'assets/images/coin.png'
                  ),
                  const Text('+10 moedas', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFFE6DDAF)))
                ],
              ).animate(target: _count == 10 ? 1 : 0)
                .visibility()
                .moveY(begin: -50, end: -400, duration: 1500.ms)
                .fadeOut(delay: 200.ms),
              Align(
                alignment: FractionalOffset.centerRight,
                child: Text(
                  'By Matheus Dourado',
                  style: GoogleFonts.mynerve(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE6DDAF),
                    )
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
