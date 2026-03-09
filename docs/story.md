Ich möchte ein kleine Tool bauen. Ich nutze einen Mac. Das Tool soll in der Menüzeile einen Eintrag, ein Kreis-Symbol,  hinzufügen. Es geht darum, ein Git-Repo zu überwachen.

  Das Repo liegt lokal im Verzeichnis `~/config-files`. Der Pfad soll in einer Konfigurationsdatei änderbar sein.

  Alle 30 Sekunden soll das Tool das Repo fetchen.
  Wenn es uncommitted changes gibt, soll der Kreis rot sein.
  Gibt es committed changes, die nicht gepusht sind, soll der Kreis gelb sein.
  Gibt es Changes remote, die nicht gepullt sind, soll der Kreis auch gelb sein.
  Trifft nichts davon zu, soll der Kreis die normale Vordergrundfarbe haben, um nicht aufzufallen.
  Wenn man auf das Symbol klickt, öffnet sich ein Menü mit dem Eintrag "Quit". Das beendet das Tool.
  Ein Symbol in dem Dock soll nicht angezeigt werden, nur in der Menüzeile.

