import 'package:flutter/material.dart';
import 'package:langbattle/services/web-socket.dart';
import 'package:langbattle/views/pages/login_page.dart';
import 'package:langbattle/views/widget_tree.dart';
import 'package:langbattle/widgets/hero_widget.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RegisterPage extends StatefulWidget {
  final BattleService battleService;
  const RegisterPage({super.key, required this.battleService});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController controllerEmail = TextEditingController(text: "");
  TextEditingController controllerPassword = TextEditingController(text: "");
  TextEditingController controllerName = TextEditingController(text: "");




  @override
  void initState() {
    super.initState();
    
    widget.battleService.stream.listen((event) {
    if (event["type"] == "auth_success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(battleService: widget.battleService,)),
      );
    }

    if (event["type"] == "error") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event["message"])),
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
              HeroWidget(title: "Register"),
              SizedBox(height: 20,),
              TextField(
                controller: controllerName,
                decoration: InputDecoration(
                  hintText: 'Nickname',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0)
                  ),
                  
                ),
                onEditingComplete: () {
                  setState(() {
        
                  });
                }
              ),
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
                onRegister();
              },
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              
               child: Text("Register"))
            ],
          ),
        ),
      ),
    );


  }

  void onRegister() {
    final email = controllerEmail.text.trim();
    final password = controllerPassword.text;
    final name = controllerName.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    widget.battleService.register(
      email,
      password,
      name,
    );
  }


}