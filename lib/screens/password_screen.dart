import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visitation/Colors/color.dart';
import 'package:visitation/screens/splash_screen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _checkPassword() async {
    final String password = _passwordController.text;
    String role;

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: red,
          content: Text(
            'أدخل الرقم السري',
            style: TextStyle(color: white),
          ),
        ),
      );
      return;
    }

    switch (password) {
      case 'خدمة ثانوي شباب البابا شنودة' ||
            'خدمة ثانوي شباب البابا شنوده' ||
            'خدمة ثانوى شباب البابا شنودة' ||
            'خدمة ثانوى شباب البابا شنوده' ||
            'خدمه ثانوي شباب البابا شنودة' ||
            'خدمه ثانوي شباب البابا شنوده' ||
            'خدمه ثانوى شباب البابا شنودة' ||
            'خدمه ثانوى شباب البابا شنوده':
        role = 'other';
        break;
      case 'أولاد البابا شنودة الثالث' ||
            'أولاد البابا شنوده الثالث' ||
            'اولاد البابا شنودة الثالث' ||
            'اولاد البابا شنوده الثالث':
        role = 'boy';
        break;
      case 'بنات خدمة البابا شنودة iii' ||
            'بنات خدمة البابا شنوده iii' ||
            'بنات خدمه البابا شنودة iii' ||
            'بنات خدمه البابا شنوده iii':
        role = 'girl';
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: red,
            content: Text(
              'الرقم السري غير صحيح',
              style: TextStyle(color: white),
            ),
          ),
        );
        return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('role', role);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const SplashScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.062,
                child: Text(
                  'ادخل الرقم السري',
                  style: TextStyle(
                    color: blue,
                    fontSize: MediaQuery.of(context).size.height * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.08,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: blue.withOpacity(0.4),
                      selectionHandleColor: blue,
                    ),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    cursorColor: blue,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: blue,
                        ),
                      ),
                      labelStyle: TextStyle(color: black),
                      labelText: 'الرقم السري',
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.062,
                child: ElevatedButton(
                  onPressed: _checkPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          color: white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'تأكيد',
                          style: TextStyle(
                            color: white,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
