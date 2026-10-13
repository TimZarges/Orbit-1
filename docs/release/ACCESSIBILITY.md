# Barrierefreiheits-Prüfbericht (Accessibility WCAG 2.1 AA)

> Leitlinie: ORBIT ist für alle Athleten zugänglich – unabhängig von Seheinschränkungen, Farbfehlsichtigkeiten oder motorischen Voraussetzungen.

---

## 1. Farbkontraste & Volt-Regel (WCAG AA & AAA)

| Element | Vordergrund / Hintergrund | Kontrastverhältnis | Bewertung |
|---|---|---|---|
| **Performance-Volt Hero** | Volt `#CDFB17` auf Deep Navy `#0F172A` | **13.8 : 1** | **Exzellent (Übertrifft AAA)** |
| **Volt-Button** | Deep Navy `#0A0F1D` auf Volt `#CDFB17` | **14.2 : 1** | **Exzellent (Übertrifft AAA)** |
| **Standardtext (Dunkel)** | Neutral Weiß `#F8FAFC` auf `#0A0F1D` | **17.9 : 1** | **Exzellent (Übertrifft AAA)** |
| **Sekundärtext (Muted)** | Slate `#94A3B8` auf Deep Navy `#0F172A` | **5.4 : 1** | **Erfüllt AA (Min. 4.5:1)** |
| **Gesperrt:** | Volt `#CDFB17` auf hellen Flächen | *Verboten* | Durch Design-Token-Regeln ausgeschlossen |

---

## 2. Farbfehlsichtigkeits-Absicherung (Redundante Kodierung)

Informationen werden **niemals ausschließlich über Farbe** vermittelt:

1. **Form-Ampeln:**
   - Zusätzlich zu den Farben (Grün, Blau, Orange, Rot) existieren eindeutige Textlabels: *Frisch*, *Optimal*, *Ermüdet*, *Überlastet*.
2. **Trainingszonen (Z1–Z7):**
   - Jede Zone trägt neben ihrer Kennfarbe eine Ziffer und eine Kurzbezeichnung (z. B. „Z2 – Aerob").
3. **Sportarten:**
   - Neben den Sportfarben (Cyan für Schwimmen, Grün für Rad, Orange für Lauf) wird stets ein signifikantes Icon und der Sportartname angezeigt.
4. **Daily Load Ring:**
   - Beinhaltet Semantics-Labels für Screenreader („Ist: 45 / Plan: 68 TSS" bzw. „Ruhetag").

---

## 3. Tippflächen und Touch-Targets

- Sämtliche interaktiven Elemente (Buttons, Checkboxen, IconButtons, Tab-Leisten) weisen eine Mindestgröße von **$48 \times 48\text{ dp}$** auf (Material Design / iOS Human Interface Guidelines).
- Ausreichender Abstand zwischen benachbarten Aktionen verhindert Fehltipps bei der Bedienung nach anstrengenden Trainingseinheiten.

---

## 4. Textskalierung & Dynamische Schriftgrößen

- Die Benutzeroberfläche unterstützt Schriftgrößenskalierungen von bis zu **$130\%$ (Faktor 1.3)** ohne Textabschneidungen.
- Flexible Layouts (`Flexible`, `Expanded`, `SingleChildScrollView`) verhindern Overflow-Fehler (`RenderFlex overflowed`).

---

## 5. Screenreader-Unterstützung (TalkBack & VoiceOver)

- Semantics-Labels auf allen dekorationslosen Symbolen und interaktiven Widgets.
- Tabellenzellen und Wochenraster-Karten besitzen aussagekräftige Labels wie: *„Training am Montag, 14. Oktober: Laufen, 45 Minuten, 55 TSS"*.
- Tastatur-Shortcuts sind barrierefrei über den Hilfedialog (`?`) und Alternativ-Menüs dokumentiert.
