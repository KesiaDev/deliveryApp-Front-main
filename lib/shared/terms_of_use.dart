import 'package:animations/animations.dart';
import 'package:delivery_front/shared/dialogs/policy_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TermsOfUse extends StatelessWidget {
  const TermsOfUse({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Condições'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 16),
                text:
                    "Ao criar uma conta ou utilizar a plataforma você concorda com nossos termos.\n\n",
                children: [
                  TextSpan(
                    text: "Termos & Condições ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        showModal(
                          context: context,
                          configuration: FadeScaleTransitionConfiguration(),
                          builder: (context) {
                            return PolicyDialog(
                              mdFileName: 'terms_and_conditions.md',
                            );
                          },
                        );
                      },
                  ),
                  TextSpan(text: "e "),
                  TextSpan(
                    text: "Política de privacidade!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return PolicyDialog(
                              mdFileName: 'privacy_policy.md',
                            );
                          },
                        );
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'CONCORDAR E CONTINUAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('CANCELAR'),
            ),
          ],
        ),
      ),
    );
  }
}
