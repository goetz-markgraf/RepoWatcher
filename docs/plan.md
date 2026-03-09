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
- Falls Datei nicht existiert: Default-Konfiguration erstellen
- JSON Encoding/Decoding mit Codable

### 4. Git-Service Implementation
**GitService.swift** übernimmt:
- `checkStatus()` → GitStatus Enum zurückgeben (asynchron via DispatchQueue.global())
- Git-Befehle via `Process` ausführen
- Alle 5 Minuten automatisch `git fetch` ausführen
- Status-Checks in dieser Reihenfolge:
  1. Upstream branch prüfen: `git rev-parse --abbrev-ref @{u}`
     - Falls Fehler (kein upstream) → `.noUpstream` (ROT)
  2. Uncommitted changes prüfen: `git status --porcelain`
     - Falls Output nicht leer → `.uncommitted` (ROT)
  3. Unpushed commits prüfen: `git log @{u}..HEAD --oneline`
     - Falls Output nicht leer → `.unpushed` (GELB)
  4. Unpulled changes prüfen: `git log HEAD..@{u} --oneline`
     - Falls Output nicht leer → `.unpulled` (GELB)
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
- NSMenu mit einem Item: "Quit"
- Action: NSApplication.shared.terminate()

### 6. Timer für periodisches Fetching
- `Timer.scheduledTimer` mit 5 Minuten Intervall (300 Sekunden)
- Bei jedem Tick:
  1. `git fetch` ausführen (asynchron auf DispatchQueue.global())
  2. Git-Status prüfen (asynchron)
  3. Menüleisten-Icon aktualisieren (auf main queue)

### 7. App-Lifecycle
**main.swift**:
- Pure AppKit Entry Point mit @main und NSApplicationMain()
- AppDelegate als NSApplicationDelegate

## Kritische Dateien
- **main.swift**: App Entry Point (@main)
- **AppDelegate.swift**: Menüleisten-Integration
- **Services/GitService.swift**: Git-Logik (asynchron)
- **Services/ConfigService.swift**: Konfigurationsmanagement
- **Info.plist**: LSUIElement = YES

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
6. Nach 5 Minuten: git fetch wird automatisch ausgeführt
7. Click auf Menüleisten-Icon → "Quit" erscheint
8. "Quit" klicken → App beendet sich

## Offene Fragen
- Keine - Plan ist vollständig
