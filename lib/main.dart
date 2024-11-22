import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: "256505339310-s154tbd4qsf4b34guboha3ioqtsb9kob.apps.googleusercontent.com",
  scopes: [
    calendar.CalendarApi.calendarScope,
    'https://www.googleapis.com/auth/dialogflow',
  ],
);

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot TFG',
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _eventNameController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final String sessionId = Uuid().v4();
  GoogleSignInAccount? _currentUser;
  calendar.CalendarApi? _calendarApi;
  String? _accessToken;
  DateTime? _selectedDateTime;
  bool _showEventFields = false; // Controle de visibilidade do formulário de evento

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
        if (_currentUser != null) {
          _initializeCalendarApi();
        }
      });
    });
    _googleSignIn.signInSilently();
    _loadAuthToken();
  }

  Future<void> _initializeCalendarApi() async {
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) {
      print("Erro ao obter o cliente autenticado.");
      return;
    }
    _calendarApi = calendar.CalendarApi(authClient);
  }

  Future<void> _loadAuthToken() async {
    final jsonString = await rootBundle.loadString('assets/tfg-final-440713-a62f73e08dad.json');
    final jsonMap = jsonDecode(jsonString);
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonMap);
    final scopes = [
      calendar.CalendarApi.calendarScope,
      'https://www.googleapis.com/auth/dialogflow',
    ];

    try {
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      setState(() {
        _accessToken = client.credentials.accessToken.data;
      });
    } catch (e) {
      print('Erro ao obter o token de acesso da conta de serviço: $e');
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });

        _messages.add({
          'data': 0,
          'message': 'Data e hora selecionadas: ${_selectedDateTime!.toLocal()}',
        });
      }
    }
  }

  // Função para verificar palavras-chave
  void _checkForEventKeywords(String message) {
    if (message.toLowerCase().contains("criar evento") || message.toLowerCase().contains("agendar evento")) {
      setState(() {
        _showEventFields = true; // Exibe o campo para criar evento
      });
    } else {
      setState(() {
        _showEventFields = false; // Esconde o campo se não for um comando de evento
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'data': 1, 'message': message});
    });

    _controller.clear();

    // Verificar palavras-chave
    _checkForEventKeywords(message);

    if (_accessToken == null) {
      print("Token de conta de serviço não disponível.");
      setState(() {
        _messages.add({'data': 0, 'message': 'Erro ao autenticar com o Dialogflow.'});
      });
      return;
    }

    final response = await http.post(
      Uri.parse('https://dialogflow.googleapis.com/v2/projects/tfg-final-440713/agent/sessions/$sessionId:detectIntent'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'queryInput': {
          'text': {
            'text': message,
            'languageCode': 'pt-BR',
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      print("Resposta completa do Dialogflow: $decodedResponse");

      var botMessage = decodedResponse['queryResult']['fulfillmentText'] ?? "Não entendi. Poderia perguntar de outra forma?";
      setState(() {
        _messages.add({'data': 0, 'message': botMessage});
      });

      var intentData = decodedResponse['queryResult']['intent'];
      if (intentData != null && intentData['displayName'] != null) {
        var intentName = intentData['displayName'];
        if (intentName == "Criar Evento") {
          if (_selectedDateTime != null) {
            String eventName = _eventNameController.text.isNotEmpty
                ? _eventNameController.text
                : "Evento Sem Nome";
            await _createEvent(_selectedDateTime!.toIso8601String(), eventName);
            _selectedDateTime = null;
            _eventNameController.clear();
          }
        }
      }
    } else {
      print('Erro ao se comunicar com o Dialogflow: ${response.body}');
    }
  }

  Future<void> _createEvent(String dateTime, String eventName) async {
    if (_calendarApi == null) return;

    try {
      DateTime startDateTime = DateTime.parse(dateTime);

      var event = calendar.Event()
        ..summary = eventName
        ..description = 'Evento criado via Dialogflow'
        ..start = (calendar.EventDateTime()
          ..dateTime = startDateTime
          ..timeZone = 'America/Sao_Paulo')
        ..end = (calendar.EventDateTime()
          ..dateTime = startDateTime.add(Duration(hours: 1))
          ..timeZone = 'America/Sao_Paulo');

      var createdEvent = await _calendarApi!.events.insert(event, 'primary');
      if (createdEvent.htmlLink != null) {
        setState(() {
          _messages.add({'data': 0, 'message': 'Evento criado: ${createdEvent.htmlLink}'});
          print(createdEvent.htmlLink);
        });
      } else {
        setState(() {
          _messages.add({'data': 0, 'message': 'Erro ao criar evento.'});
        });
      }
    } catch (e) {
      print('Erro ao criar evento: $e');
      setState(() {
        _messages.add({'data': 0, 'message': 'Erro ao criar o evento.'});
      });
    }
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
      print("Usuário logado: ${_googleSignIn.currentUser!.displayName}");
      _messages.add({'data': 0, 'message': 'Usuário logado: ${_googleSignIn.currentUser!.displayName}'});
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() async{
    if (_googleSignIn.currentUser != null) {
      await _googleSignIn.signOut();
      print("Usuário deslogado.");
      _messages.add({'data': 0, 'message': 'Usuário deslogado.'});
    }
  } 
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Chatbot TFG")),
        actions: [
          if (_currentUser == null)
            Tooltip(
              message: 'Fazer login',
              child: IconButton(
                icon: Icon(Icons.login_rounded),
                onPressed: _handleSignIn,
              ),
            ),
          if (_currentUser != null)
            Tooltip(
              message: 'Sair',
              child: IconButton(
                icon: Icon(Icons.logout_rounded),
                onPressed: _handleSignOut,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ChatMessage(
                message: _messages[index]["message"],
                isUser: _messages[index]["data"] == 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textInputAction: TextInputAction.none,
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Digite uma mensagem'),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  tooltip: 'Enviar Mensagem',
                  icon: Icon(Icons.send_rounded),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
          if (_showEventFields) ...[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                textAlign: TextAlign.center,
                controller: _eventNameController,
                decoration: InputDecoration(hintText: 'Título do evento'),
              ),
            ),
              IconButton(
                tooltip: 'Selecionar Data e Hora',
                icon: Icon(Icons.calendar_today_rounded),
                onPressed: () => _selectDateTime(context),
              ),
            if (_selectedDateTime != null)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text('Data e hora selecionadas: ${_selectedDateTime!.toLocal()}'),
              ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.all(10),
      child: Card(
        color: isUser ? Colors.blue[100] : Colors.grey[300],
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            message,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
