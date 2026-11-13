# Задание для Астра — недостающие материалы Lernzeit

Lernzeit — приложение для Android TV (Sony BRAVIA 3, Godot 4) для добровольной тренировки
по программе **1-го класса (Бавария)**. Управление только пультом: стрелки и OK.
Всё учебное содержание — **на немецком**. Уже сделаны математика до 20, буквы, слоги, слова
и немецкая озвучка голосом **HeyGen «Nele — Friendly & Natural»**.

Нужно подготовить **3 архива** (по одному на пакет), в порядке важности.

---

## Общие правила для всех архивов

1. **Только Full HD.** Фоны — ровно 1920×1080. Никаких 4K.
2. **Элементы — PNG RGBA с настоящей прозрачностью** (не белый и не «шахматный» фон).
   Размер — не больше, чем нужно на экране (предметы 300–400 px, иконки до 256 px).
3. **Никакого текста на картинках** — ни немецкого, ни русского, ни цифр в кнопках.
   Все тексты, числа и ответы приложение рисует само.
4. **Стиль как у существующих наборов:** яркий детский мультяшный стиль, мягкие тени,
   толстый контур, без мелких деталей (смотрят с дивана с 3 метров).
5. **Имена файлов — латиница, без пробелов и умлаутов:** `Logik_Shape_Circle_Red.png`,
   `Loewe`, `Tuer`, `Fuss`.
6. **Структура архива:**
   ```
   <Имя_архива>/
     Game_Assets/        только то, что пойдёт в приложение
     Reference_Only/     макеты экранов (JPEG), только для ориентира
     documentation/
       README_FOR_CLAUDE.md
       ASSET_MANIFEST.json   (список файлов: имя, размер в px, назначение)
   ```
7. Готовые экраны **не нужны** как картинки — только отдельные элементы.
   Задания (что показать, какой правильный ответ) описываются **в JSON**, приложение
   собирает экран само.

---

## Пакет 1 — «Logik» (самое важное: предмет сейчас пустой)

Архив: `Lernzeit_Logik_Kit.zip`. Один фон `Logik_Background_1920x1080.png` и UI:
панель вопроса, панель для ряда картинок, клетка-слот, клетка «?», кнопка ответа
(обычная / в фокусе / неактивная), рамка фокуса — всё **без текста**.

### 1.1 «Muster fortsetzen» — Продолжи узор
- Фигуры: круг, квадрат, треугольник, звезда, сердце, ромб — каждая в **4 цветах**
  (красный, синий, жёлтый, зелёный) → 24 PNG, 256×256.
- Предметы для узоров: яблоко, груша, листик, мяч, рыбка, цветок — 6 PNG, 256×256.
- Приложение само строит ряды (ABAB, AABB, ABC…). JSON не нужен.

### 1.2 «Formen erkennen» — Узнай фигуры
- Фигуры крупно: Kreis, Quadrat, Dreieck, Rechteck — 4 PNG, 400×400 (один нейтральный цвет).
- По **3 предмета на каждую форму**: Kreis — Ball, Uhr, Pizza; Quadrat — Fenster, Würfel, Kissen;
  Dreieck — Pizzastück, Schild, Zelt; Rechteck — Tür, Buch, Handy → 12 PNG, 360×360.
- JSON `formen.json`: `[{"shape": "Kreis", "objects": ["Ball", "Uhr", "Pizza"]}, …]`.

### 1.3 «Unterschiede finden» — Найди отличия
- **8 пар картинок** (слева / справа), 760×560, простые сцены (комната, сад, пляж…).
- В каждой паре **ровно 3 отличия**, крупные и заметные (нет шапки, другой цвет мяча…).
- JSON `unterschiede.json`: для каждой пары — имя файлов и **3 прямоугольника отличий**
  в пикселях правой картинки: `{"pair": "Garten", "diffs": [[x, y, w, h], …]}`.

### 1.4 «Reihenfolge» — Порядок
- **6 историй по 3–4 картинки**, 360×360: Samen → Keimling → Blume; Ei → Küken → Huhn;
  Morgen → Mittag → Abend; Teig → Ofen → Kuchen; Raupe → Puppe → Schmetterling;
  Schneeflocke → Schneemann → Schmelzen.
- JSON `reihenfolge.json`: `[{"story": "Blume", "frames": ["…_1.png", "…_2.png", "…_3.png"]}, …]`.

---

## Пакет 2 — «Lesen: Sätze und Texte»

Архив: `Lernzeit_Lesen_Saetze_Texte.zip`.

### 2.1 Предложения — 30 штук
- Очень короткие (3–5 слов), только простые слова, лучше из уже существующих:
  Ameise, Apfel, Ast, Auto, Ball, Banane, Blume, Bus, Dach, Dose, Ente, Esel, Fisch, Fuß, Gabel,
  Gans, Haus, Hose, Hut, Igel, Insel, Katze, Kuh, Lama, Lampe, Limo, Löwe, Mama, Maus, Melone,
  Mond, Nase, Nest, Ohr, Oma, Opa, Papa, Pilz, Pinsel, Puppe, Rad, Rakete, Rose, Sofa, Sonne,
  Stern, Tasche, Tasse, Tomate, Tür, Uhr, Uhu, Wal, Wolke.
- Примеры: «Die Maus ist klein.», «Oma hat eine Tasse.», «Der Ball ist rot.», «Papa sitzt auf dem Sofa.»
- **К каждому предложению — картинка-сцена**, 480×360, и она должна отличаться от других
  (ребёнок выбирает одну из трёх).
- JSON `saetze.json`: `[{"id": "s01", "text": "Die Maus ist klein.", "picture": "Satz_s01.png"}, …]`.

### 2.2 Мини-тексты — 8 штук
- 2–3 предложения, затем **вопрос** и **3 картинки-ответа** (одна верная).
- Пример: «Lena hat einen Hund. Der Hund ist braun. Er spielt mit einem Ball.» —
  «Womit spielt der Hund?» — Ball ✔, Puppe, Auto.
- Картинки ответов 300×300; можно переиспользовать существующие слова.
- JSON `texte.json`: `[{"id": "t01", "text": "…", "question": "…", "answers": ["Ball.png", "Puppe.png", "Auto.png"], "correct": 0}, …]`.

---

## Пакет 3 — «Textaufgaben» (математика, текстовые задачи)

Архив: `Lernzeit_Textaufgaben_Kit.zip`.
- Фон-сценка 1920×1080 (луг, пруд или полянка — с местом сверху под текст).
- Персонажи и предметы для задач, **по одному предмету на файл**, 200×200:
  птица, утка, бабочка, рыбка, яблоко, морковка, шарик, машинка, кекс, котёнок → 10 PNG.
- 30 задач в JSON `textaufgaben.json` в пределах 10 (плюс и минус), например:
  `{"text": "3 Vögel sitzen auf dem Ast. 2 Vögel kommen dazu. Wie viele Vögel sind es jetzt?", "object": "Vogel", "a": 3, "b": 2, "op": "+", "answer": 5}`.

---

## Пакет 4 — озвучка к новым материалам (после пакетов 1–3)

Тем же голосом **Nele**, тем же форматом: WAV PCM 16 bit, моно, 44 100 Гц, скорость 0.9,
лишняя тишина обрезана, громкость выровнена. Один файл — одна фраза, `phrases.tsv`
с колонками `file / text / duration_seconds`.

| Файл | Текст |
|---|---|
| g_prompt_muster | Wie geht das Muster weiter? |
| g_prompt_formen | Welches Ding hat diese Form? |
| g_prompt_unterschiede | Finde die Unterschiede! |
| g_prompt_reihenfolge | Was passiert zuerst? |
| g_prompt_reihenfolge_next | Und was kommt danach? |
| shape_Kreis / shape_Quadrat / shape_Dreieck / shape_Rechteck | Kreis · Quadrat · Dreieck · Rechteck |
| le_prompt_satz | Lies den Satz. Welches Bild passt? |
| le_prompt_text | Lies die Geschichte. |
| ta_prompt | Hör gut zu und rechne. |
| satz_s01 … satz_s30 | каждое предложение из `saetze.json` |
| text_t01 … text_t08 | каждый мини-текст **вместе с вопросом** из `texte.json` |
| ta_01 … ta_30 | каждая текстовая задача из `textaufgaben.json` |
| word_<Новое_слово> | все **новые** слова из пакетов 1–3 (Kreis, Ball, Vogel, Hund …) |

Важно: в «Чтении» приложение **не** проигрывает предложение до ответа (ребёнок должен
прочитать сам) — запись звучит после правильного ответа.

---

## Как проверить перед отправкой
- Открыть каждый PNG на тёмном фоне — нет белой подложки и обрезанных краёв.
- Ни на одной картинке нет букв или цифр.
- Каждый файл, упомянутый в JSON, есть в `Game_Assets`, и наоборот.
- Немецкие тексты проверены на ошибки (артикли, заглавные буквы у существительных).
- Озвучку прослушать: особенно новые слова и длинные предложения.
