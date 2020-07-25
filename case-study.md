# Case-study оптимизации

## Актуальная проблема
В нашем проекте возникла серьёзная проблема.

Необходимо было обработать файл с данными, чуть больше ста мегабайт.

У нас уже была программа на `ruby`, которая умела делать нужную обработку.

Она успешно работала на файлах размером пару мегабайт, но для большого файла она работала слишком долго, и не было понятно, закончит ли она вообще работу за какое-то разумное время.

Я решил исправить эту проблему, оптимизировав эту программу.

## Формирование метрики
Для того, чтобы понимать, дают ли мои изменения положительный эффект на быстродействие программы я придумал использовать такую метрику:
замер потребляемой памяти в мегабайтах, время выполнения программы.
Также обращаю внимание на показатели GC.stat такие как:
total_allocated_objects - снижение этого показателя будет показывать уменьшение потребляемой памяти,
malloc_increase - снижение этого показателя будет говорить, что больше объектов помещается в Ruby слот и дополнительной памяти выделяется меньше.
Для этого был написан скрипт show_metrics.rb использующий гем benchmark и метод получения статистики сборщика мусора GC.stat

## Гарантия корректности работы оптимизированной программы
Программа поставлялась с тестом. Выполнение этого теста в фидбек-лупе позволяет не допустить изменения логики программы при оптимизации.

## Feedback-Loop
Для того, чтобы иметь возможность быстро проверять гипотезы я выстроил эффективный `feedback-loop`, который позволил мне получать обратную связь по эффективности сделанных изменений за *время, которое у вас получилось*

Вот как я построил `feedback_loop`:
1. Проводим замер метрик.
2. Находим точку роста с помощью профайлера
3. Рефакторим код, оптимизируем точку роста
4. Фиксируем результат

## Вникаем в детали системы, чтобы найти главные точки роста
Для того, чтобы найти "точки роста" для оптимизации я воспользовался гемы memory_profiler и ruby_prof

Вот какие проблемы удалось найти и решить

### Ваша находка №1
Для того, чтобы программа на большом объеме данных выполнилась в приемлемое время, заменил код оптимизированным по CPU кодом из прошлого урока,
замер потребляемой памяти показал 2559Mb на большом файле и 28Mb на малом файле. Для чистоты эксперимента возвращаю исходный код текущего урока,
замер на малом объеме показывает 29Mb, на большом объеме программа выполняется бесконечно.
В фидбэк лупе решил использовать файл размером 180_000 строк.

Замер метрик показывает:
Использовано памяти: 134 MB
Всего объектов: 302008
Статистика GC:
total_allocated_objects: 1308163
malloc_increase_bytes: 1195512
Finish in 6.0

memory_profiler указывает на точку роста в строке с использованием Date.parse и приведением времени к ISO8601.
Но несмотря на точку роста мы понимаем, что у нас при чтении файла содержимое полностью выгружается в память 
и это является основным потребителем памяти в текущий момент.
Изменяем обработку входящих данных с полной выгрузки содержимого в память на построчные чтение и запись с помощью IO.each и 
Oj::StreamWriter.

Метрики ожидаемо уменьшились:
Использовано памяти: 94 MB
Всего объектов: 92346
Статистика GC:
total_allocated_objects: 775790
malloc_increase_bytes: 976
Finish in 0.19


### Ваша находка №2
- какой отчёт показал главную точку роста
- как вы решили её оптимизировать
- как изменилась метрика
- как изменился отчёт профилировщика

### Ваша находка №X
- какой отчёт показал главную точку роста
- как вы решили её оптимизировать
- как изменилась метрика
- как изменился отчёт профилировщика

## Результаты
В результате проделанной оптимизации наконец удалось обработать файл с данными.
Удалось улучшить метрику системы с *того, что у вас было в начале, до того, что получилось в конце* и уложиться в заданный бюджет.

*Какими ещё результами можете поделиться*

## Защита от регрессии производительности
Для защиты от потери достигнутого прогресса при дальнейших изменениях программы *о performance-тестах, которые вы написали*