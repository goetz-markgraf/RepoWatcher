# RepoWatcher - Git Repository Menu Bar Monitor

## Context
Der Benutzer möchte ein macOS Menüleisten-Tool entwickeln, das ein lokales Git-Repository (~config-files) überwacht und visuelles Feedback über den Repository-Status gibt. Das Tool soll diskret in der Menüleiste arbeiten (kein Dock-Icon) und den Benutzer über uncommitted changes (rot), unpushed commits (gelb) oder unpulled remote changes (gelb) informieren.

## Technologie-Stack
- Pure AppKit (kein SwiftUI)
- NSStatusBar für Menüleisten-Integration
- Foundation für File I/O und Timer
- DispatchQueue für asynchrone Git-Operationen

## Implementierungsplan

### 1. Xcode-Projekt erstellen
- Neues macOS App-Projekt in Xcode
- Bundle Identifier: `com.repowatcher.app`
- AppKit Lifecycle (kein SwiftUI)
- Minimum Deployment Target: macOS 13.0

### 2. Projektstruktur
```
RepoWatcher/
├── main.swift                     # App Entry Point (@main)
├── AppDelegate.swift              # NSApplicationDelegate für Menu Bar
├── Models/
│   ├── Config.swift               # Konfigurationsmodell
│   └── GitStatus.swift            # Git-Status Enum
├── Services/
│   ├── ConfigService.swift        # Config laden/speichern
│   └── GitService.swift           # Git-Operationen (async)
└── Controllers/
    └── StatusBarController.swift  # Menu Bar Management
```

### 3. Konfigurationsdatei
**Pfad**: `~/.config/repowatcher/config.json`
**Format**:
```json
{
  "repositoryPath": "~/config-files"
}
```

**ConfigService.swift**:
- Konfiguration aus ~/.config/repowatcher/config.json laden
- Tilde-Expansion (~/ → /Users/username/)
- Falls Datei nicht existiert: Default-Konfiguration erstellen UND speichern
- JSON Encoding/Decoding mit Codable

### 4. Git-Service Implementation
**GitService.swift** übernimmt:
- `checkStatus()` → GitStatus Enum zurückgeben (asynchron via DispatchQueue.global())
- Git-Befehle via `Process` ausführen
- `hasRemoteChanges()` → Lightweight Remote-Check mit `git ls-remote` (ohne vollständiges Fetch)
- Initial beim Start: `git fetch` ausführen
- Periodisch (alle 5 Minuten): Nur Status-Check (nutzt ls-remote für Remote-Changes)
- Status-Checks in dieser Reihenfolge:
  1. Upstream branch prüfen: `git rev-parse --abbrev-ref @{u}`
     - Falls Fehler (kein upstream) → `.noUpstream` (ROT)
  2. Uncommitted changes prüfen: `git status --porcelain`
     - Falls Output nicht leer → `.uncommitted` (ROT)
  3. Unpushed commits prüfen: `git log @{u}..HEAD --oneline`
     - Falls Output nicht leer → `.unpushed` (GELB)
  4. Unpulled changes prüfen: `hasRemoteChanges()` via `git ls-remote`
     - Vergleicht remote SHA mit lokalem tracking branch SHA
     - Falls unterschiedlich → `.unpulled` (GELB)
  5. Sonst → `.clean` (NORMAL)

**GitStatus Enum**:
```swift
enum GitStatus {
    case noUpstream   // Rot (kein upstream branch)
    case uncommitted  // Rot
    case unpushed     // Gelb
    case unpulled     // Gelb
    case clean        // Normal (System-Vordergrundfarbe)
}
```

### 5. Menüleisten-Integration
**AppDelegate.swift**:
- `NSApplicationDelegate` implementieren
- LSUIElement = YES in Info.plist (versteckt Dock-Icon)
- NSStatusBar.system.statusItem erstellen
- Status-Icon als Kreis-Symbol (SF Symbol: "circle.fill")
- Farbe basierend auf GitStatus:
  - noUpstream → `.red`
  - uncommitted → `.red`
  - unpushed/unpulled → `.yellow`
  - clean → `.labelColor` (System-Vordergrundfarbe)

**Menu**:
- NSMenu mit folgenden Items:
  - Repository-Pfad (disabled, zur Info)
  - "Jetzt aktualisieren" (nur wenn gültiges Repo) - führt `git fetch` + Status-Update aus
  - "⚠️ Kein gültiges Git-Repository" (disabled, nur wenn ungültiges Repo oder HomeDir)
  - "Quit" - Action: NSApplication.shared.terminate()

**Repository-Validierung**:
- Beim Start prüfen: Pfad != HomeDir, Pfad existiert, .git Ordner vorhanden
- Falls ungültig: Menü zeigt Warnung statt "Jetzt aktualisieren", Timer wird nicht gestartet

### 6. Timer für periodische Status-Checks
- `Timer.scheduledTimer` mit 5 Minuten Intervall (300 Sekunden)
- Initial beim Start:
  1. `git fetch` ausführen (asynchron, nur beim Start)
  2. Status-Update
- Bei jedem Timer-Tick (alle 5 Minuten):
  1. Nur Status-Check (nutzt lightweight `git ls-remote` für Remote-Changes)
  2. Menüleisten-Icon aktualisieren (auf main queue)
- "Jetzt aktualisieren" im Menü:
  1. Manuelles `git fetch` durchführen
  2. Anschließend Status-Update

### 7. App-Lifecycle
**main.swift**:
- Pure AppKit Entry Point mit @main und NSApplicationMain()
- AppDelegate als NSApplicationDelegate

## Kritische Dateien
- **main.swift**: App Entry Point (@main)
- **AppDelegate.swift**: Menüleisten-Integration, lädt Config und startet StatusBarController
- **Controllers/StatusBarController.swift**: Repository-Validierung, Menü-Setup, Timer-Management
- **Services/GitService.swift**: Git-Logik (asynchron), ls-remote für lightweight Remote-Check
- **Services/ConfigService.swift**: Konfigurationsmanagement, erstellt Default-Config beim ersten Start
- **Models/GitStatus.swift**: Status-Enum mit Farb-Mapping
- **Models/Config.swift**: Codable Config-Struktur
- **Info.plist**: LSUIElement = YES (kein Dock-Icon)

## Verifikation
1. App in Xcode builden und starten
2. Prüfen: Kreis-Symbol erscheint in Menüleiste
3. Prüfen: Kein Dock-Icon sichtbar
4. Prüfen: Konfigurationsdatei wird unter ~/.config/repowatcher/config.json erstellt
5. Im Test-Repository Änderungen machen:
   - Datei ändern (nicht committen) → Kreis wird rot
   - Änderung committen (nicht pushen) → Kreis wird gelb
   - Remote-Changes simulieren → Kreis wird gelb
   - Alles clean → Kreis wird normal (Systemfarbe)
   - Branch ohne upstream → Kreis wird rot
6. Nach 5 Minuten: Status-Check wird durchgeführt (nutzt ls-remote, kein vollständiges fetch)
7. Click auf Menüleisten-Icon → Menü öffnet sich mit Repository-Pfad, "Jetzt aktualisieren" (oder Warnung bei ungültigem Repo) und "Quit"
8. "Jetzt aktualisieren" klicken → git fetch + Status-Update
9. "Quit" klicken → App beendet sich
10. Bei ungültigem Repository-Pfad (HomeDir oder kein .git Ordner): Menü zeigt Warnung statt "Jetzt aktualisieren"

## Offene Fragen
- Keine - Plan ist vollständig
