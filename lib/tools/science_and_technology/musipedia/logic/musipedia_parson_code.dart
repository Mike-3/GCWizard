import 'package:http/http.dart' as http;

String inputToAsciiArt(String parson_code) {
  parson_code =_cleanInput(parson_code);

  final Map<int, Map<int, String>> grid = {};

  int x = 0;
  int y = 0;

  void put(int x, int y, String c) {
    grid.putIfAbsent(y, () => {});
    grid[y]![x] = c;
  }

  // Startpunkt
  put(x, y, '*');

  for (final c in parson_code.split('')) {
    if (c == 'R') {
      put(x + 1, y, '-');
      x += 2;
      put(x, y, '*');
    }
    else if (c == 'U') {
      put(x + 1, y - 1, '/');
      x += 2;
      y -= 2;
      put(x, y, '*');
    }
    else if (c == 'D') {
      put(x + 1, y + 1, r'\');
      x += 2;
      y += 2;
      put(x, y, '*');
    }
  }

  final minX = grid.values.expand((r) => r.keys).reduce((a, b) => a < b ? a : b);
  final maxX = grid.values.expand((r) => r.keys).reduce((a, b) => a > b ? a : b);
  final minY = grid.keys.reduce((a, b) => a < b ? a : b);
  final maxY = grid.keys.reduce((a, b) => a > b ? a : b);

  final out = StringBuffer();
  for (int yy = minY; yy <= maxY; yy++) {
    for (int xx = minX; xx <= maxX; xx++) {
      out.write(grid[yy]?[xx] ?? ' ');
    }
    out.writeln();
  }

  return out.toString();
}

String _cleanInput(String input) {
  return input.toUpperCase().replaceAll(RegExp(r'[^RUD\*]'), '');
}

Future<String> callSoapService({
  required Uri endpoint,
  required String soapAction,
  required String bodyXml,
}) async {
  final envelope = bodyXml;
//   final envelope = '''
// <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
// xmlns:xsd="http://www.w3.org/2001/XMLSchema"
// xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
//   <soapenv:Body>
//     $bodyXml
//   </soapenv:Body>
// </soapenv:Envelope>
// ''';

  final response = await http.post(
    endpoint,
    headers: {
      'Content-Type': 'text/xml; charset=utf-8',
      'SOAPAction': soapAction,
    },
    body: envelope,
  );

  if (response.statusCode != 200) {
    throw Exception(
      'SOAP Fehler ${response.statusCode} ${response.reasonPhrase}:: ${response.body}',
    );
  }

  return response.body;
}

Future<void> main() async {
  // final input = '*RUURDDDDRUURDR';
  // print(inputToAsciiArt(input));
//LZj9fxfvh2Ife3mf3kcI
  final result = await callSoapService(
    endpoint: Uri.parse('https://www.musipedia.org/soap/index.php'),
    soapAction: 'http://www.musipedia.org/#index', //'http://www.musipedia.org/#search', //'http://www.musipedia.org/#search', //'searchMelody',
      bodyXml: '''
      <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                  xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
                  xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
                  xmlns:tns="http://www.musipedia.org/"
                  xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">
   <soapenv:Header/>
   <soapenv:Body>
      <tns:search soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
         <username xsi:type="xsd:string">gcwizard1</username>
         <q123hash xsi:type="xsd:string">05e63e59ebaf69c389749365ba8f7b79</q123hash>
         <q1collection xsi:type="xsd:string">Musipedia</q1collection>
         <q2query xsi:type="xsd:string">*RUURDDDDRUURDR</q2query>
         <q3keywords xsi:type="xsd:string">Beethoven</q3keywords>
         <q8categories xsi:type="xsd:string">C</q8categories>
      </tns:search>
   </soapenv:Body>
</soapenv:Envelope>
      '''
//     bodyXml: '''
// <?xml version="1.0" encoding="UTF-8"?>
// <soapenv:Envelope
//     xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
//     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
//     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
//     xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
//     xmlns:tns="http://www.musipedia.org/">
//
//   <soapenv:Header/>
//   <soapenv:Body soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
//     <tns:search>
//       <username xsi:type="xsd:string">gcwizard1</username>
//       <q123hash xsi:type="xsd:string">05e63e59ebaf69c389749365ba8f7b79</q123hash>
//       <q1collection xsi:type="xsd:string">Musipedia</q1collection>
//       <q2query xsi:type="xsd:string">*RUURDDDDRUURDR</q2query>
//       <q3keywords xsi:type="xsd:string">Beethoven</q3keywords>
//
//       <q8categories xsi:type="xsd:string">C</q8categories>
//     </tns:search>
//
//   </soapenv:Body>
// </soapenv:Envelope>
// ''',
  );
  // <tns:searchMelody>
  // <tns:query>RUURDDDDRUURDR</tns:query>
  // </tns:searchMelody>
  print(result);

  // <tns:search soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  // <username xsi:type="xsd:string">gcwizard1</username>
  // <q123hash xsi:type="xsd:string">05e63e59ebaf69c389749365ba8f7b79</q123hash>
  // <q1collection xsi:type="xsd:string">Musipedia</q1collection>
  // <q2query xsi:type="xsd:string">*RUURDDDDRUURDR</q2query>
  // <q3keywords xsi:type="xsd:string">Beethoven</q3keywords>
  // <q8categories xsi:type="xsd:string">C</q8categories>
  // </tns:search>
}