import 'dart:convert';

import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:firedart/firedart.dart';
import 'package:http/http.dart' as http;
import 'package:mailer2/mailer.dart';

TeleDart teledart;
var currentKey = "";
final String instructionString = '''<b>How to use this bot ?</b>\nTo start you should create a new table with all replys to your form. You can do it in the creator.
<b>Remember that the first column of your table must contain emails !!</b> After that you must give an access to this table to eshendo.projects@gmail.com.
And now, you can use this bot to send messages to the people, who replied to your form. Use /new to register a table, then use /send to send a message to all emails from table.\n\n
For more info type /help. 
''';
int flag = 0;
final PROJECT_ID = "formsbot-1e8ed";
final URL = "http://127.0.0.1:5000/loadSheet";

main(List<String> arguments) {
  teledart = TeleDart(Telegram(''), Event());
  teledart.start().then((me) => print('${me.username} is initialised'));
  teledart.onCommand('start')
    .listen((message) =>  showInstruction(message));
  teledart.onCommand('new')
    .listen((message) => { teledart.replyMessage(message, 'Please, send a link to your Google Sheets table.'), flag = 1 });
  teledart.onCommand('list')
    .listen((message) => listMails(message));
  teledart.onCommand('instruction')
    .listen((message) => showInstruction(message));
  teledart.onCommand('send')
    .listen((message) => { teledart.replyMessage(message, 'What do you want to send ?'), flag = 2 });
  teledart.onCommand('change')
    .listen((message) => { teledart.replyMessage(message, 'Provide a new key.'), flag = 3 });
  teledart.onMessage().listen((message) => proccessMessage(message));
  teledart.onUrl().listen((message) => proccessMessage(message));
  teledart.onCallbackQuery().listen((callback) => changeCurrentKey(callback.data, callback.message, true));
  Firestore.initialize(PROJECT_ID);
}

proccessMessage(Message message){
  switch (flag){
    case 0:
      teledart.replyMessage(message, 'Wat ?');
      break;
    case 1:
      print(message.text);
      newForm(message.text, message);
      break;
    case 2:
      teledart.replyMessage(message, 'Sending....');
      sendToMails(message.text);
      break;
    case 3:
      changeCurrentKey(message.text, message, false);
      break;
  }
  flag = 0;

}

newForm(String link, Message message) async {
  print(link.split("/"));
  var map = {
    "key": link.split("/")[5],
  };
  await http.post(URL, body:json.encode(map)).then((value) => proccessNewForm(json.decode(value.body), message));

}

listMails(Message message){
  Firestore.instance.collection("forms").document(currentKey).get().then((value) => {
    teledart.replyMessage(message, value.map["emails"].toString())
  });

}

showInstruction(Message message){
  teledart.replyMessage(message, instructionString, parse_mode: 'html');
}

sendToMails(String text){
  Firestore.instance.collection("forms").document(currentKey).get().then((value) => actualSendToMails(value.map["emails"], text));
}

void actualSendToMails(List<dynamic> mails, String text){
  
  var options = new GmailSmtpOptions()
      ..username='eshendo.projects@gmail.com'
      ..password='';

  var emailTransport = new SmtpTransport(options);


  var envelope = new Envelope()
      ..from = "eshendo.projects@gmail.com"
      ..recipients = new List<String>.from(mails)
      ..text = text;

  emailTransport.send(envelope)
    .then((envelope) => print('Success'))
    .catchError((e) => print('Error occurred: $e'));
}

void changeCurrentKey(String key, Message message, bool flag){
  if (key != "nope"){
    currentKey = key;
    teledart.replyMessage(message, 'Switched');
  }
  if (flag){
    var markup = ReplyKeyboardRemove();
    markup.remove_keyboard = true;
    var res = teledart.telegram.editMessageReplyMarkup(message_id: message.message_id, chat_id: message.chat.id);
    print(res);
  }
}

listSecrets(){
  /* TODO: make this shit work !! */
}

generateMarkup(String id){
  List<List<InlineKeyboardButton>> buttons = [
    [InlineKeyboardButton(text: "No", callback_data: "nope"), InlineKeyboardButton(text: "Yes", callback_data: id)]
  ];
  return InlineKeyboardMarkup(inline_keyboard: buttons);
}

proccessNewForm(var emails, Message message) async{
  await Firestore.instance.collection("forms").add(emails).then((value) => {
    teledart.replyMessage(message, 'Your secret is ${value.id}, switch to this secret ?', reply_markup: generateMarkup(value.id))
  });
}
