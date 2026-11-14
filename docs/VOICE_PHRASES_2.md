# Lernzeit — озвучка, часть 2 (для Nele)

Тот же голос **HeyGen «Nele — Friendly & Natural»**, та же скорость 0.9 и тот же формат, что в части 1:
WAV PCM 16 bit, моно, 44 100 Гц, тишина по краям обрезана, громкость выровнена,
`phrases.tsv` (file / text / duration_seconds). Один файл = одна фраза, имя файла — из первой колонки.

Приложение уже ждёт эти файлы: достаточно сконвертировать их (`tools/convert_voice.sh`) —
код менять не нужно. Пока файла нет, это место просто остаётся без голоса.

## 1. Логика — вопросы (6)
| Файл | Текст |
|---|---|
| lg_prompt_muster | Wie geht das Muster weiter? |
| lg_prompt_form_thing | Welches Ding hat diese Form? |
| lg_prompt_thing_form | Welche Form hat das? |
| lg_prompt_next | Was kommt danach? |
| lg_prompt_first | Was war zuerst? |
| lg_prompt_middle | Was passiert dazwischen? |

## 2. Названия фигур (после правильного ответа в «Formen») (4)
| Файл | Текст |
|---|---|
| shape_Kreis | Kreis |
| shape_Quadrat | Quadrat |
| shape_Dreieck | Dreieck |
| shape_Rechteck | Rechteck |

## 3. Подсказки, которых не было в части 1 (9)
| Файл | Текст |
|---|---|
| tip_lg_muster | Sag die Reihe leise auf. Was wiederholt sich? |
| tip_lg_formen | Fahre mit dem Finger am Rand entlang. Ist er rund oder eckig? |
| tip_lg_reihenfolge | Überlege: Was passiert am Anfang, was am Ende? |
| tip_zr | Wie groß ist der Sprung von einer Zahl zur nächsten? |
| tip_equal | Zähle beide Gruppen und vergleiche die Zahlen. |
| tip_de_find | Schau genau auf die Form von … (дальше приложение добавит букву) |
| tip_de_build | Welcher Buchstabe kommt als Nächstes? Schau oben auf das Wort. |
| tip_le_word_pic | Lies das Wort Buchstabe für Buchstabe. |
| tip_le_pic_word | Wie heißt das Bild? Mit welchem Laut beginnt es? |

## 4. Главный экран и время (2)
| Файл | Текст |
|---|---|
| goal_done | Tagesziel geschafft! Toll! |
| limit | Für heute ist Schluss! Du hast heute schon viel geübt. Morgen geht es weiter. |

## 5. Новые слова «Logik · Formen» (6)
Уже есть: Ball, Uhr, Tür. Нужны:

| Файл | Текст |
|---|---|
| word_Pizza | Pizza |
| word_Fenster | Fenster |
| word_Wuerfel | Würfel |
| word_Kissen | Kissen |
| word_Zelt | Zelt |
| word_Pizzastueck | Pizzastück |

---
**Итого 27 файлов.**
Самое важное — разделы 1 и 2: тогда в Логике будут звучать все вопросы.
