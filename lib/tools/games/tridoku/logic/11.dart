void main() {
  // Definiere die Struktur des Tridokus
  Map<int, List<String>> tridoku = {
    1: ['A'],
    2: ['A', 'B', 'C'],
    3: ['A', 'B', 'C', 'D', 'E'],
    4: ['A', 'B', 'C', 'D', 'E','F','G'],
    5: ['A', 'B', 'C', 'D', 'E','F','G','H','I'],
    6: ['A', 'B', 'C', 'D', 'E','F','G','H','I','J','K'],
    7: ['A', 'B', 'C', 'D', 'E','F','G','H','I','J','K','L','M'],
    8: ['A', 'B', 'C', 'D', 'E','F','G','H','I','J','K','L','M','N','O'],
    9: ['A', 'B', 'C', 'D', 'E','F','G','H','I','J','K','L','M','N','O','P','Q'],
    // Füge hier weitere Reihen hinzu, falls nötig
  };

  // Alle Felder durchlaufen und die verbundenen Felder ausgeben
  for (int reihe in tridoku.keys) {
    for (String spalte in tridoku[reihe]!) {
      String feld = '$reihe$spalte';
      List<String> angrenzendeFelder = ermitteleAngrenzendeFelder(feld, tridoku);
      print('Feld $feld ist verbunden mit: $angrenzendeFelder');
    }
  }
}


List<String> ermitteleAngrenzendeFelder(String feld, Map<int, List<String>> tridoku) {
  // Extrahiere die Reihe und Spalte aus dem Feld (z.B. 1A -> 1 und A)
  int reihe = int.parse(feld[0]);
  String spalte = feld[1];

  // Liste der angrenzenden Felder
  List<String> angrenzendeFelder = [];

  // Hole die aktuelle Reihe und den Index der Spalte
  List<String> aktuelleReihe = tridoku[reihe] ?? [];
  int spaltenIndex = aktuelleReihe.indexOf(spalte);

  // Nachbarn in derselben Reihe (links/rechts)
  if (spaltenIndex != -1) {
    if (spaltenIndex > 0) {
      angrenzendeFelder.add('$reihe${aktuelleReihe[spaltenIndex - 1]}'); // Links
    }
    if (spaltenIndex < aktuelleReihe.length - 1) {
      angrenzendeFelder.add('$reihe${aktuelleReihe[spaltenIndex + 1]}'); // Rechts
    }
  }

  // Nachbarn in der darunter liegenden Reihe (unten links/ unten rechts), wenn vorhanden
  if (tridoku.containsKey(reihe + 1)) {
    List<String> untereReihe = tridoku[reihe + 1]!;
    // Unten rechts (falls vorhanden)
    if (spaltenIndex < untereReihe.length) {
      angrenzendeFelder.add('${reihe + 1}${untereReihe[spaltenIndex]}');
    }
    // Unten links (nur falls es ein entsprechendes Feld gibt)
    if (spaltenIndex > 0 && spaltenIndex - 1 < untereReihe.length) {
      angrenzendeFelder.add('${reihe + 1}${untereReihe[spaltenIndex - 1]}');
    }
  }

  // Nachbarn in der darüber liegenden Reihe (oben links/oben rechts), wenn vorhanden
  if (tridoku.containsKey(reihe - 1)) {
    List<String> obereReihe = tridoku[reihe - 1]!;
    // Oben rechts (falls vorhanden)
    if (spaltenIndex < obereReihe.length) {
      angrenzendeFelder.add('${reihe - 1}${obereReihe[spaltenIndex]}');
    }
    // Oben links (nur falls es ein entsprechendes Feld gibt)
    if (spaltenIndex > 0 && spaltenIndex - 1 < obereReihe.length) {
      angrenzendeFelder.add('${reihe - 1}${obereReihe[spaltenIndex - 1]}');
    }
  }

  return angrenzendeFelder;
}