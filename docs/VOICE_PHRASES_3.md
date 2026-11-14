# Lernzeit — что ещё нужно озвучить (часть 3, для Nele)

Голос **HeyGen «Nele — Friendly & Natural»**, скорость генерации 0.9, **без** дополнительного замедления.
Прислать **готовые WAV** (PCM 16 bit, моно, 44 100 Гц) + `phrases.tsv` (`file / text / duration_seconds`),
а не ссылки — ссылки устаревают. Один файл = одна фраза, имя файла — из первой колонки.

Код уже готов: достаточно положить файлы, ничего менять не нужно. Пока файла нет, это место просто без голоса.
Всё остальное в приложении (≈ 560 фраз) уже озвучено.

## 1. Слова — новые картинки из «Deutsch_Words_Part1» (24) — самое важное
Звучат в «Буквах», «Словах», «Первом звуке» и после правильного ответа.

| Файл | Текст | Файл | Текст |
|---|---|---|---|
| word_Clown | Clown | word_Xylofon | Xylofon |
| word_Computer | Computer | word_Yak | Yak |
| word_Jacke | Jacke | word_Yacht | Yacht |
| word_Joghurt | Joghurt | word_Yogamatte | Yogamatte |
| word_Jojo | Jojo | word_Zebra | Zebra |
| word_Qualle | Qualle | word_Zahn | Zahn |
| word_Quelle | Quelle | word_Zitrone | Zitrone |
| word_Quark | Quark | word_Aepfel | Äpfel |
| word_Vase | Vase | word_Aermel | Ärmel |
| word_Violine | Violine | word_Oel | Öl |
| word_Vulkan | Vulkan | word_Oelkanne | Ölkanne |
| word_Uebertopf | Übertopf | word_Uebungsheft | Übungsheft |

## 2. Вопросы Логики, которых ещё нет (2)
| Файл | Текст |
|---|---|
| lg_prompt_thing_form | Welche Form hat das? |
| lg_prompt_middle | Was passiert dazwischen? |

## 3. Подсказки после первой ошибки (14)
Звучат, только если в родительском разделе язык подсказок — немецкий.

| Файл | Текст |
|---|---|
| tip_de_find | Schau genau auf die Form von … *(без буквы: приложение добавит её само)* |
| tip_de_build | Welcher Buchstabe kommt als Nächstes? Schau oben auf das Wort. |
| tip_le_word_pic | Lies das Wort Buchstabe für Buchstabe. |
| tip_le_pic_word | Wie heißt das Bild? Mit welchem Laut beginnt es? |
| tip_le_satz | Lies jedes Wort. Was siehst du auf dem Bild? |
| tip_le_text | Lies die Geschichte noch einmal. Die Antwort steht darin. |
| tip_lg_muster | Sag die Reihe leise auf. Was wiederholt sich? |
| tip_lg_formen | Fahre mit dem Finger am Rand entlang. Ist er rund oder eckig? |
| tip_lg_reihenfolge | Überlege: Was passiert am Anfang, was am Ende? |
| tip_lg_unterschiede | Vergleiche Stück für Stück: oben, in der Mitte, unten. |
| tip_zr | Wie groß ist der Sprung von einer Zahl zur nächsten? |
| tip_equal | Zähle beide Gruppen und vergleiche die Zahlen. |
| tip_ta_plus | Es kommen welche dazu: Zähle alle zusammen. |
| tip_ta_minus | Es gehen welche weg: Zähle nur die ohne Kreuz. |

## 4. Главный экран, время, мини-игра (5)
| Файл | Текст |
|---|---|
| goal_done | Tagesziel geschafft! Toll! |
| limit | Für heute ist Schluss! Du hast heute schon viel geübt. Morgen geht es weiter. |
| game_target_a | Lass alle Ballons mit … *(обрывается: дальше приложение скажет цифру или букву)* |
| game_target_b | … platzen! |
| game_done | Super gespielt! |

---
**Итого 45 файлов.** Самое важное — раздел 1 (слова).

Не нужно записывать: подсказки с числами (`tip_sub_equation`, `tip_add_missing` …) — в них каждый раз
другие числа, они остаются только текстом. Когда придут новые слова, предложения и тексты из
`docs/TASK_GPT_2.md`, для них понадобятся такие же записи `word_*`, `syl_*`, `satz_*`, `text_*`, `ta_*`.
