import 'package:flutter/material.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/people/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GoogleSignInAccount? _currentUser;
  String _contactText = '';
  List<Message> inboxMessage = [];
  List<dynamic> inboxMessage2 = [
    {"id": "TestID", "subject": "TestSubject", "snippet": "TestBody"}
  ];
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // 'https://www.googleapis.com/auth/contacts.readonly',
    scopes: <String>[
      GmailApi.gmailReadonlyScope,
      GmailApi.gmailModifyScope,
      PeopleServiceApi.contactsReadonlyScope
    ],
  );

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error); // ignore: avoid_debugPrint
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    if (user != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: user,
            ),
            title: Text(user.displayName ?? ''),
            subtitle: Text(user.email),
          ),
          Expanded(
              child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
                children: inboxMessage2.map((message) {
              // return ListTile(
              //   title: Text(message['subject'] ?? "null"),
              //   subtitle: Text(message['snippet'] ?? "null"),
              // );
              return Container(
                padding: EdgeInsets.all(8.0),
                margin: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.grey.shade400),
                child: Column(
                  children: [
                    Text("ID:${message['id']}"),
                    Text("Subject:${message['subject']}"),
                    Text("Body:${message['snippet']}"),
                    Text("Date:${message['date']}"),
                    Text("From:${message['from']}"),
                    Text("To:${message['to']}"),
                  ],
                ),
              );
            }).toList()),
          )),
          ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('SIGN OUT'),
          ),
          ElevatedButton(
            onPressed: _handleGetContact,
            child: const Text('REFRESH'),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text('You are not currently signed in.'),
          ElevatedButton(
            onPressed: _handleSignIn,
            child: const Text('SIGN IN'),
          ),
        ],
      );
    }
  }

  Future<void> _handleGetContact() async {
    setState(() {
      _contactText = 'Loading contact info...';
    });

    final auth.AuthClient? client = await _googleSignIn.authenticatedClient();

    assert(client != null, 'Authenticated client missing!');

    final PeopleServiceApi peopleApi = PeopleServiceApi(client!);
    final ListConnectionsResponse response1 =
        await peopleApi.people.connections.list(
      'people/me',
      personFields: 'names',
    );
    final String? firstNamedContactName =
        _pickFirstNamedContact(response1.connections);

    setState(() {
      if (firstNamedContactName != null) {
        _contactText = 'I see you know $firstNamedContactName!';
      } else {
        _contactText = 'No contacts to display.';
      }
    });
    try {
      final GmailApi gmailApi = GmailApi(client);
      // find message with subject
      // final ListMessagesResponse response = await gmailApi.users.messages.list(
      //   'me',
      //   q: 'subject:"Gmail-Test" is:unread',
      // );

      final ListMessagesResponse response =
          await gmailApi.users.messages.list('me');
      final List<Message>? messages = response.messages;

      setState(() {
        inboxMessage = messages!;
      });

      // final http.Response response2 = await http.get(Uri.parse('https://gmail.googleapis.com/auth/gmail/v1/users/me/messages/{messageId}'),
      //   headers: await user.authHeaders,
      // //headers: {'Authorization': 'Bearer $token'},
      // );

      if (messages != null) {
        messages.forEach((message) async {
          final messageDetails =
              await gmailApi.users.messages.get('me', message.id!);
          final messageSnippet = messageDetails.snippet;
          final payload = messageDetails.payload;
          final headers = payload!.headers;
          var from, to, date, subject;
          headers!.forEach((element) {
            if (element.name == "Subject") {
              subject = element.value;
            } else if (element.name == "Date") {
              date = element.value;
            } else if (element.name == "From") {
              from = element.value;
            } else if (element.name == "To") {
              to = element.value;
            }
          });

          // debugPrint(
          //     "ID => ${message.id} // Subject => $subject // Body => $messageSnippet // From => $from // To => $to // Date => $date");

          setState(() {
            inboxMessage2.add({
              "id": message.id,
              "from": from,
              "to": to,
              "date": date,
              "subject": subject,
              "snippet": messageSnippet
            });
          });
        });
        // for (final message in messages) {
        // final messageDetails =
        //     await gmailApi.users.messages.get('me', message.id!);

        // final messageSnippet = messageDetails.snippet;
        // debugPrint('Message ID: ${message.id}');
        // debugPrint('Message Snippet: $messageSnippet');
        // setState(() {
        //   inboxMessage2[index]["id"] = message.id;
        //   inboxMessage2[index]["snippet"] = messageSnippet;
        // });

        // final modifyRequest = ModifyMessageRequest()
        //   ..removeLabelIds = ['UNREAD'];
        // await gmailApi.users.messages
        //     .modify(modifyRequest, 'me', message.id!);
        // debugPrint('Message marked as read.');
        // }
      }
    } catch (e) {
      debugPrint('Error retrieving messages: $e');
    } finally {}
  }

  String? _pickFirstNamedContact(List<Person>? connections) {
    return connections
        ?.firstWhere(
          (Person person) => person.names != null,
        )
        .names
        ?.firstWhere(
          (Name name) => name.displayName != null,
        )
        .displayName;
  }

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _handleGetContact();
      }
    });
    _googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Sign In + googleapis'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
