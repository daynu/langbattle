import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/widget_tree.dart';
import 'package:langbattle/widgets/hero_widget.dart';


class LoginPage extends StatefulWidget {
  final BattleService battleService;
  LoginPage({super.key, required this.battleService});


  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController controllerEmail = TextEditingController(text: "");
  TextEditingController controllerPassword = TextEditingController(text: "");
  late final StreamSubscription _sub;


  @override
  void initState() {
    super.initState();
     _sub = widget.battleService.stream.listen((event) {
    if (!mounted) return;

    if (event["type"] == "error") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event["message"])),
      );
    }

    if (event["type"] == "auth_success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WidgetTree(battleService: widget.battleService,),
        ),
      );
    }
  });
}

  @override
  void dispose() {
    controllerEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              HeroWidget(title: "Login"),
              SizedBox(height: 20,),
              TextField(
                controller: controllerEmail,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0)
                  ),
                ),
               
                onEditingComplete: () {
                  setState(() {
        
                  });
                },
              ),
              SizedBox(height: 20,),
              TextField(
                obscureText: true,
                controller: controllerPassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0)
                  ),
                ),
                
                onEditingComplete: () {
                  setState(() {
                    
                  });
                },
              ),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: () 
              {
                onLogin();
              },
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              
               child: Text("Login"))
            ],
          ),
        ),
      ),
    );


  }

  void onLogin()
  {
    final email = controllerEmail.text.trim();
    final password = controllerPassword.text.trim();


    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    widget.battleService.login(email, password);

  }}