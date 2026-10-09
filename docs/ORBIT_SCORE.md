# VORLÄUFIG – nicht freigegeben: ORBIT Score

> Dieser Entwurf definiert den ORBIT Score. Er wird in Phase 10 erst nach ausdrücklicher Freigabe in das UI übernommen.

## Zweck
Der ORBIT Score bietet Athleten und Trainern einen leicht verständlichen Index (0–100), um die heutige kumulierte Trainingsbelastung in Relation zum aktuellen Leistungsvermögen und zur Historie einzuordnen. 
**Wichtig:** Es handelt sich um eine orientierende Trainingskennzahl, nicht um eine medizinische Aussage oder ein Gesundheitsversprechen.

## Definition und Formel
Der Score vergleicht die Trainingsbelastung der letzten 7 Tage (ATL) plus die des heutigen Tages mit der chronischen Belastung der letzten 42 Tage (CTL). Er skaliert den ermittelten Wert auf einen Index.

`Score = 50 - (TSB / Referenz_CTL) * Faktor`

Wenn `TSB = 0` (ausgeglichen), ist der Score `50` (neutral, typisch).
Ist `TSB` stark negativ (hohe Ermüdung), sinkt der Score gegen 0.
Ist `TSB` stark positiv (sehr frisch), steigt der Score gegen 100.

## Grenzen und dünne Datenlage
- Wenn die CTL unter 15 liegt (z.B. neue Nutzer in den ersten Wochen), ist der Score statistisch zu anfällig.
- **Verhalten:** Bei `CTL < 15` wird kein Score berechnet. Stattdessen wird in der UI ein Hinweis angezeigt: "Daten sammeln: Noch X Tage Training benötigt".
