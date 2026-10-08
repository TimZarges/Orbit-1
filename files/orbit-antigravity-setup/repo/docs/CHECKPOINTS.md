# Checkpoints (Autopilot-Protokoll)

> Hier hält der Agent im Autopilot (`/phase-run`) alle Entscheidungen fest, die sonst ein STOPP gewesen wären.
> **Neueste Einträge oben.** Lies nach jeder Phase zuerst alle Einträge mit `RISIKO-HOCH`.

## Legende
- **RISIKO-HOCH:** Security-Rules, Auth/Functions, Datenmodell, Formeln/ORBIT Score, Datenschutz. Bitte vor dem Merge prüfen.
- **RISIKO-MITTEL:** UX-Grundentscheidungen, Architektur, Abhängigkeiten.
- **RISIKO-NIEDRIG:** Details, die sich leicht ändern lassen.

## Eintragsformat
```
### [Phase NN] Kurztitel · RISIKO-…
- **STOPP-Punkt/Anlass:** (z. B. „STOPP 1 aus Phasendatei" oder „Plan selbst freigegeben")
- **Entscheidung:** was getan wurde
- **Alternative:** was die Option gewesen wäre
- **Begründung:**
- **Bitte prüfen:** konkret, womit (Datei/Test/Gerät)
- **Rückholen:** wie man es rückgängig macht (Commit/Branch)
```

## Branch-Reihenfolge (zum Mergen von unten nach oben)
| Reihenfolge | Branch | Basis | Status |
|---|---|---|---|
| – | – | – | – |

## Einträge
(noch keine)
