# references/ — только визуальные ориентиры (не загружаются приложением)

Эта папка лежит **вне** Godot-проекта (`lernzeit/`), поэтому Godot её не импортирует и в APK она не попадает.
Здесь макеты экранов, концепт-арт, превью и документация комплектов графики.
По требованиям README самих комплектов эти изображения **нельзя использовать как интерактивные экраны**:
экраны упражнений собираются из отдельных спрайтов (`lernzeit/assets/...`), а весь текст, буквы и цифры рисует Godot.

| Папка | Источник | Что внутри |
|---|---|---|
| `deutsch_buchstaben_kit_v1/` | `Lernzeit_Deutsch_Buchstaben_Complete_Kit_v1.zip` | 6 макетов 1920×1080, 6 иллюстраций-концептов, 3 превью, `README_FOR_CLAUDE.md`, `ASSET_MANIFEST.json` |
| `subtraction_10_kit_v1/` | `Lernzeit_Subtraction_10_Complete_Kit.zip` | 6 концептов 1672×941, превью, `README_FOR_CLAUDE.txt`, `ASSET_MANIFEST.json` |
| `counting_10_screens_mockups/` | `Lernzeit_Counting_10_Six_New_Screens.zip` | 6 готовых экранов 1920×1080 со вшитым немецким текстом и цифрами. В архиве нет README, манифеста и отдельных спрайтов |

`import_report.json` — отчёт последнего запуска `tools/import_kits.py` (что записано, что пропущено, конфликты).
