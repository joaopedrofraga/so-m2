import 'package:flutter/material.dart';

// ignore: must_be_immutable
class EnderecoTextformfieldWidget extends StatelessWidget {
  TextEditingController enderecontroller;

  EnderecoTextformfieldWidget({super.key, required this.enderecontroller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: enderecontroller,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.developer_board, color: Colors.red),
        labelText: 'Insira o Endereço Virtual',
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      style: TextStyle(color: Colors.white),
    );
  }
}
