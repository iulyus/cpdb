///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем OAuth_Токен;
Перем УдалитьИсточник;

// Интерфейсная процедура, выполняет регистрацию команды и настройку парсера командной строки
//   
// Параметры:
//   ИмяКоманды 	- Строка										- Имя регистрируемой команды
//   Парсер 		- ПарсерАргументовКоманднойСтроки (cmdline)		- Парсер командной строки
//
Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Отправить файл на Yandex-Диск");
	
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ПутьКФайлу", "Путь к файлу для отправки на Yandex-диск");
	
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-params",
		"Файлы JSON содержащие значения параметров,
		|могут быть указаны несколько файлов разделенные "";""
		|(параметры командной строки имеют более высокий приоритет)");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-file",
		"Путь к локальному файлу для помещения на Yandex-Диск");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-list",
		"Путь к локальному файлу со списком файлов,
		|которые будут помещены на Yandex-Диск
		|(параметр -file игнорируется)");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ya-token",
		"Token авторизации");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ya-path",
		"Путь к файлу на Yandex-Диск");
	
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды,
		"-check-hash",
		"(TBE) Проверять совпадение хешей скопированных файлов");
		
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, 
		"-delsrc",
		"Удалить исходные файлы после отправки");
	
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры // ЗарегистрироватьКоманду()

// Интерфейсная процедура, выполняет текущую команду
//   
// Параметры:
//   ПараметрыКоманды 	- Соответствие						- Соответствие параметров команды и их значений
//
// Возвращаемое значение:
//	Число - код возврата команды
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
	
	ЗапускПриложений.ПрочитатьПараметрыКомандыИзФайла(ПараметрыКоманды["-params"], ПараметрыКоманды);
	
	ЭтоСписокФайлов = Истина;

	ПутьКФайлу				= ПараметрыКоманды["-list"];
	Если НЕ ЗначениеЗаполнено(ПутьКФайлу) Тогда
		ПутьКФайлу				= ПараметрыКоманды["-file"];
		ЭтоСписокФайлов	= Ложь;
	КонецЕсли;
	OAuth_Токен				= ПараметрыКоманды["-ya-token"];
	ЦелевойПуть				= ПараметрыКоманды["-ya-path"];
	УдалитьИсточник			= ПараметрыКоманды["-delsrc"];
	
	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();
	
	Если ПустаяСтрока(ПутьКФайлу) Тогда
		Лог.Ошибка("Не указан путь к файлу для помещения на Yandex-Диск");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;
	
	Если ПустаяСтрока(OAuth_Токен) Тогда
		Лог.Ошибка("Не задан Token авторизации");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	МассивОтправляемыхФайлов = Новый Массив;
	ФайлИнфо = Новый Файл(ПутьКФайлу);
	ЯндексДиск = Неопределено;

	// Если целевой путь не указан - тогда используется корень Яндекс-диска
	Если ПустаяСтрока(ЦелевойПуть) Тогда
		ЦелевойПуть = "";
	Иначе
		// Определяем наличие каталога
		СоздатьПапкуНаЯДиске(ЯндексДиск, ЦелевойПуть);
	КонецЕсли;
	
	Если ЭтоСписокФайлов Тогда
		МассивОтправляемыхФайлов = ПрочитатьСписокФайлов(ПутьКФайлу);
	КонецЕсли;
	
	// Добавляем файл (или файл-список файлов) списка для закачки на Я-Диск
	МассивОтправляемыхФайлов.Добавить(ФайлИнфо.Имя);

	Для Каждого ОтправляемыйФайл Из МассивОтправляемыхФайлов Цикл
		
		РезультатОтправки = ОтправитьФайлНаЯДиск(ЯндексДиск, ФайлИнфо.Путь, ОтправляемыйФайл, ЦелевойПуть);
		Если НЕ РезультатОтправки Тогда
			Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
		КонецЕсли;
	КонецЦикла;
	
	Возврат ВозможныйРезультат.Успех;
	
КонецФункции // ВыполнитьКоманду()

// Функция возвращает массив имен файлов архива
//   
// Параметры:
//   ПутьКСписку 	- Строка			- путь к файлу со списком файлов архива
//
// Возвращаемое значение:
//	Массив(Строка) - список файлов архива
//
Функция ПрочитатьСписокФайлов(ПутьКСписку)

	МассивФайловЧастей = Новый Массив();

	ЧтениеСписка = Новый ЧтениеТекста(ПутьКСписку, КодировкаТекста.UTF8);
	СтрокаСписка = ЧтениеСписка.ПрочитатьСтроку();
	Пока СтрокаСписка <> Неопределено Цикл
		Если ЗначениеЗаполнено(СокрЛП(СтрокаСписка)) Тогда
			МассивФайловЧастей.Добавить(СтрокаСписка);
		КонецЕсли;
		
		СтрокаСписка = ЧтениеСписка.ПрочитатьСтроку();
	КонецЦикла;
	
	ЧтениеСписка.Закрыть();

	Возврат МассивФайловЧастей;

КонецФункции // ПрочитатьСписокФайлов()

// Функция отправки файла на Yandex-Диск
//
// Параметры:
//   ЯДиск		 		- ЯндексДиск				- объект ЯндексДиск для работы с yandex-диском
//   Каталог	 		- Строка					- расположение загружаемого файла
//   ИмяФайла		 	- Булево					- имя загружаемого файла
//   ЦелевойПуть 		- ЯндексДиск				- путь на yandex-диске, куда будет загружен файл
//
// Возвращаемое значение:
//	Число - код возврата команды
//
Функция ОтправитьФайлНаЯДиск(ЯДиск, Знач Каталог, Знач ИмяФайла, Знач ЦелевойПуть)
	
	Если НЕ ЗначениеЗаполнено(ЯДиск) Тогда
		
		ЯДиск = Новый ЯндексДиск;
		ЯДиск.УстановитьТокенАвторизации(OAuth_Токен);
	КонецЕсли;
	
	СвойстваДиска = ЯДиск.ПолучитьСвойстваДиска();
	Лог.Отладка("Всего доступно %1 байт", СвойстваДиска.total_space);
	Лог.Отладка("Из них занято %1 байт", СвойстваДиска.used_space);
	
	СвободноМеста = СвойстваДиска.total_space - СвойстваДиска.used_space;
	Лог.Отладка("Копируемый файл: каталог %1, имя файла %2", Каталог, ИмяФайла);
	ИсходныйФайл = Новый Файл(Каталог + "\" + ИмяФайла);
	ИмяЗагружаемогоФайла = ЦелевойПуть + "/" + ИсходныйФайл.Имя;
	
	Если СвободноМеста < ИсходныйФайл.Размер() Тогда
		Лог.Ошибка("Недостаточно места на ЯДиске для копирования файла %1: есть %2, надо %3"
				, ИсходныйФайл.Имя
				, СвободноМеста
				, ИсходныйФайл.Размер());
		Возврат Ложь;
	КонецЕсли;
	
	Попытка
		ЯДиск.ЗагрузитьНаДиск(ИсходныйФайл.ПолноеИмя, ИмяЗагружаемогоФайла);
		Лог.Информация("Файл загружен %1", ИсходныйФайл.Имя);
	Исключение
		Лог.Ошибка("Ошибка загрузки файла %1 в %2: %3"
				, ИсходныйФайл.Имя
				, ИмяЗагружаемогоФайла
				, ИнформацияОбОшибке());
	КонецПопытки;

	Попытка
		ЯДиск.ПолучитьСвойстваРесурса(ИмяЗагружаемогоФайла);
	Исключение
		Лог.Ошибка("Ошибка при получении свойств файла: %1", ИнформацияОбОшибке());
	КонецПопытки;
	
	Если УдалитьИсточник Тогда
		УдалитьФайлы(ИсходныйФайл.ПолноеИмя);
		Лог.Информация("Исходный файл %1 удален", ИсходныйФайл.ПолноеИмя);
	КонецЕсли;
	
	Возврат Истина;
КонецФункции // ОтправитьФайлНаЯДиск()

// Создает папку на Я-Диске
//
// Параметры:
//   ЯДиск		 		- ЯндексДиск				- объект ЯндексДиск для работы с yandex-диском
//   ЦелевойПуть 		- ЯндексДиск				- путь на yandex-диске к создаваемому каталогу
//
// Возвращаемое значение:
//   Строка   - Созданный путь
//
Функция СоздатьПапкуНаЯДиске(ЯДиск, Знач ЦелевойПуть)

	Если НЕ ЗначениеЗаполнено(ЯДиск) Тогда
		ЯДиск = Новый ЯндексДиск;
		ЯДиск.УстановитьТокенАвторизации(OAuth_Токен);
	КонецЕсли;
	
	ТекущийПуть = "";
	Попытка
		ЯДиск.СоздатьПапку(ЦелевойПуть);
	Исключение
		Лог.Ошибка("Ошибка при создании папки %1: %2", ЦелевойПуть, ИнформацияОбОшибке());
	КонецПопытки;
	
	Возврат ТекущийПуть;

КонецФункции // СоздатьПапкуНаЯДиске()

Лог = Логирование.ПолучитьЛог("ktb.app.cpdb");