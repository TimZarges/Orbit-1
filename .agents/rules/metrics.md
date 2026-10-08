---
trigger: model_decision
description: "Anwenden bei Arbeit an Trainingskennzahlen: Normalized Power, TSS, IF, CTL/ATL/TSB, Zonen, Power-Duration-Kurve, ORBIT Score, Schwimm-/Laufbelastung, Testvektoren."
---

# Kennzahlen-Regeln

**Vollständig lesen:** @docs/specs/METRICS.md

1. Formeln **serverseitig** (TypeScript, Cloud Functions) maßgeblich. Dart nur kleine Vorschau-Variante für den Workout Builder.
2. Beide Seiten testen gegen dieselben JSON-Testvektoren in `testvectors/` (inkl. Randfälle: leere Daten, Lücken, Pausen).
3. Jede Formel im Code **mit Formel und Annahmen kommentiert** (Deutsch). Methodenwahl (rTSS/hrTSS, sTSS) begründen und in `docs/DECISIONS.md` festhalten.
4. **ORBIT Score:** Definition erst nach meiner Freigabe (STOPP), dokumentiert in `docs/ORBIT_SCORE.md`. Bei dünner Datenlage keinen Score, sondern Hinweis. Kein medizinischer Anspruch.
5. Kein Code oder Text aus Golden Cheetah (GPL) oder von TrainingPeaks übernehmen.
6. Standard-UI nutzt neutrale Begriffe, Fachkürzel nur in der Experten-Ebene (siehe `docs/DESIGN.md`, Erfahrungsstufen).
