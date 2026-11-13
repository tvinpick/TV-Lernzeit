# Lernzeit — фразы для озвучки (всё на немецком)

Формат: один файл = одна фраза, **OGG или WAV, моно, 44,1 кГц**, без тишины в начале/конце,
одинаковая громкость. Голос — спокойный, дружелюбный, медленный (для 1-го класса).
Имя файла — как в первой колонке (`.ogg` или `.wav`).

Где в задании есть буква/число/слово, фраза записывается **без него**, а нужное слово
приложение подставит отдельным файлом из разделов 5–8 (например,
`de_prompt_find` + `letter_M` = «Finde den Buchstaben … M!»).

## 1. Общие реплики (11)
| Файл | Текст |
|---|---|
| ex_correct | Richtig! |
| ex_correct_2 | Super! |
| ex_correct_3 | Toll gemacht! |
| ex_correct_4 | Prima! |
| ex_wrong | Noch einmal! |
| ex_wrong_2 | Versuch es noch einmal. |
| ex_streak | Du bist richtig gut! (серия правильных ответов) |
| ex_done | Geschafft! Toll gemacht! |
| ex_done_perfect | Alles richtig! Super! |
| home_prompt | Was möchtest du heute üben? |
| pause | Zeit für eine Pause! Mach eine kleine Pause. |

## 2. Математика — задания (26)
| Файл | Текст |
|---|---|
| cnt_prompt_objects | Wie viele siehst du? |
| cnt_prompt_bigger | Welche Zahl ist größer? |
| cnt_prompt_more | Wo sind mehr Äpfel? |
| cnt_prompt_forwards | Zähle weiter! Welche Zahl fehlt? |
| cnt_prompt_backwards | Zähle rückwärts! Welche Zahl fehlt? |
| cnt_prompt_dice | Wie viele Würfelaugen sind es? |
| cnt_prompt_to_ten | Wie viele fehlen bis zehn? |
| cnt_prompt_to_twenty | Wie viele fehlen bis zwanzig? |
| add_prompt_groups | Wie viele sind es zusammen? |
| add_prompt_equation | Rechne. |
| add_prompt_dice | Wie viele Augen sind es zusammen? |
| add_prompt_missing | Welche Zahl fehlt? |
| add_prompt_choose | Welche Rechnung passt zum Bild? |
| sub_prompt_objects | Wie viele bleiben übrig? |
| sub_prompt_number_line | Springe zurück. Wo landest du? |
| sub_prompt_ten_frame | Wie viele bleiben im Zehnerfeld? |
| sub_prompt_picture | Wähle das richtige Bild. |
| cmp_prompt_smaller | Welche Zahl ist kleiner? |
| cmp_prompt_sign | Welches Zeichen passt? |
| cmp_prompt_groups | Wo sind weniger? |
| cmp_prompt_equal | Sind es gleich viele? |
| cmp_prompt_sort | Welche Reihe geht von klein nach groß? |
| sign_less | ist kleiner als |
| sign_greater | ist größer als |
| sign_equal | ist gleich |
| plus / minus / equals | plus · minus (2 отдельных файла; «ist gleich» = sign_equal) |

## 3. Немецкий и чтение — задания (10)
| Файл | Текст |
|---|---|
| de_prompt_find | Finde den Buchstaben … (дальше буква) |
| de_prompt_lower | Finde den kleinen Buchstaben zu … |
| de_prompt_upper | Finde den großen Buchstaben zu … |
| de_prompt_first | Mit welchem Buchstaben beginnt das Wort? |
| de_prompt_missing | Welcher Buchstabe fehlt? |
| de_prompt_build | Baue das Wort … (дальше слово) |
| le_prompt_syllables | Baue das Wort aus Silben! |
| le_prompt_word_pic | Lies das Wort. Welches Bild passt? |
| le_prompt_pic_word | Welches Wort passt zum Bild? |
| de_word_is | Das Wort heißt … (после ответа, дальше слово) |

## 4. Подсказки «Tipp» (без чисел, 18)
| Файл | Текст |
|---|---|
| tip_count_all | Zeige auf jedes Ding und zähle mit. |
| tip_count_rest | Zähle nur die Dinge ohne Kreuz. |
| tip_count_empty | Zähle die leeren Felder. |
| tip_dice | Zähle alle Punkte auf den Würfeln. |
| tip_number_line | Zähle die Sprünge vom blauen Punkt nach links. |
| tip_add_choose | Zähle die Sterne in jeder Gruppe. |
| tip_bigger | Beim Zählen kommt die größere Zahl später. |
| tip_smaller | Beim Zählen kommt die kleinere Zahl zuerst. |
| tip_more | Zähle beide Gruppen und vergleiche. |
| tip_fewer | Zähle beide Gruppen. Wo ist die kleinere Zahl? |
| tip_forwards | Jede Zahl ist um eins größer als die davor. |
| tip_backwards | Jede Zahl ist um eins kleiner als die davor. |
| tip_sort | Suche zuerst die kleinste Zahl. |
| tip_sign | Die offene Seite zeigt zur größeren Zahl. |
| tip_de_case | Groß und klein sehen oft ähnlich aus. Vergleiche genau. |
| tip_de_first | Sag das Wort leise. Welcher Laut kommt zuerst? |
| tip_de_missing | Lies das Wort langsam. Welcher Laut fehlt? |
| tip_le_syllables | Sprich das Wort langsam: Welche Silbe kommt zuerst? |

## 5. Числа 0–20 (21)
`num_0` … `num_20`: null, eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, zehn,
elf, zwölf, dreizehn, vierzehn, fünfzehn, sechzehn, siebzehn, achtzehn, neunzehn, zwanzig.

## 6. Буквы — название (29)
`letter_A` … `letter_Z`, `letter_AE`, `letter_OE`, `letter_UE`:
A (a), B (be), C (ze), D (de), E (e), F (ef), G (ge), H (ha), I (i), J (jott), K (ka), L (el),
M (em), N (en), O (o), P (pe), Q (ku), R (er), S (es), T (te), U (u), V (fau), W (we), X (iks),
Y (üpsilon), Z (zett), Ä, Ö, Ü.

## 7. Буквы — звук (29)
`sound_A` … `sound_Z`, `sound_AE`, `sound_OE`, `sound_UE` — как буква **звучит** в начале
слова: «aaa» (Apfel), «mmm» (Maus), «sss» (Sonne), «fff» (Fisch) и т. д. Нужны для «Anlaute».

## 8. Слова (54)
`word_<Слово>` (без умлаутов в имени файла: `word_Fuss`, `word_Loewe`, `word_Tuer`):

Ameise, Apfel, Ast, Auto, Ball, Banane, Blume, Bus, Dach, Dose, Ente, Esel, Fisch, Fuß, Gabel,
Gans, Haus, Hose, Hut, Igel, Insel, Katze, Kuh, Lama, Lampe, Limo, Löwe, Mama, Maus, Melone,
Mond, Nase, Nest, Ohr, Oma, Opa, Papa, Pilz, Pinsel, Puppe, Rad, Rakete, Rose, Sofa, Sonne,
Stern, Tasche, Tasse, Tomate, Tür, Uhr, Uhu, Wal, Wolke.

## 9. Слоги для «Lesen · Silben» (28)
`syl_<слог>` (строчными: `syl_ba`, `syl_blu`, …):
ba, blu, do, ho, lam, li, ma, me, na, o, pa, pup, ra, ro, so, son, ta, tas, to,
fa, ke, lo, mo, ne, pe, sche, se, te.

---
**Итого примерно 225 коротких файлов.** Самое важное для начала — разделы 1–3, 5, 6, 8:
с ними можно озвучить все задания. Подсказки, звуки букв и слоги — второй очередью.
