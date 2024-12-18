# SigmaPrecraft
Этот файл - не гайд по OpenComputers, а информация об программе и её эксплуатации. Все проблемы с компьютером можно загуглить или найти в гайдах.

# Как установить программу?

#### 1. Сначала нужно создать пустые файлы в папках с расширением .lua
##### root > Libraries
- graph.lua
- config.lua

##### Рабочий стол
- main.lua

#### 2. Затем копируем  содержимое из папки в каждый файл по названию соответственно. (вставить содержимое буфера можно кликом колесика мыши)
#### 3. Настроить файл config.lua по своим нуждам:
|**#**|["ID предмета"]|count|split|
|-|-|--------|---|
|**Описание**|Нужно включить расширенные подсказки (F3+H) и при наведении на вещи будет виден айди - пример: minecraft:stone|Количество предмета для поддержания|Количество предмета для одной операции (сколько будет заказываться за раз)|
|**Макс. число**|Всего предметов может быть 20|2 147 483 648|2 147 483 648|
#### 4. После всех настроек или при изменении config.lua нужно перезагружать компьютер.
#### 5. Ставим адаптер рядом с МЭ контроллером и подключаем его кабелем к компьютеру.
#### 6. Запускаем main.lua

# Возможные ошибки
- Работа с числами больше 2^31 не поддерживается - может означать, что Вы ввели в config.lua число больше этого или в вашей МЭ сети содержится больше 2 миллиардов этого предмета (поддержка чисел больше не является возможной... пытайтесь искать обходы, например вместо инваровых блоков заказывать инваровые сингулярности)
- Параметр split не должен быть больше count - измените конфигурацию предметов так, чтобы split везде был меньше count!
- Учитывайте, что у вас должны быть МЭ процессоры и их объема должно хватать на прекрафты (альтернатива: можно делать split для прекрафтов)  

# Что исправится в будущем...
- Возможность фильтра по текстовому айди + названию (для предметов, имеющих один id)
- Будет добавлена двойная буферизация для отрисовки элементов.
- Планируется добавить "режим простоя", в котором будет выбираемая картинка/анимация, а так же отображаться краткий статус предметов.
- Код программы станет чище, graph будет переписана
- Будет поддержка больше 20 предметов, а так же настройка их через кнопку
- Добавятся настраиваемые приоритеты для крафтов (пока один не сделается - не делать другой)
