// @strict-types

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Возвращает сведения о карте Umico.
// 
// Параметры:
//  НомерКарты - Строка - номер карты лояльности
// 
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураСведенияОКартеUmico.
Функция ПолучитьСведенияОКарте(НомерКарты) Экспорт

	Ресурс = "/customers/" + НомерКарты + "/balances";
	СтруктураОтвета = ВыполнитьHTTPЗапрос("balance", "GET", Ресурс);
	Возврат ОбработатьОтветПоСведениямОКарте(СтруктураОтвета);

КонецФункции

// Регистрирует данных о чеке в Umico.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ,ДокументСсылка.ЧекККМВозврат,ДокументСсылка.РеализацияТоваровУслуг,ДокументСсылка.ВозвратТоваровОтКлиента
// 
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico
Функция ЗарегистрироватьЧек(Документ) Экспорт

	Ответ = UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico();

	ЭтоПродажа = ЭтоПродажа(Документ);

	ИдентификаторЧекаПродажи = Неопределено;

	ДокументОснование = Неопределено;

	Если Не ЭтоПродажа Тогда
		Если ТипЗнч(Документ) = Тип("ДокументСсылка.ЧекККМВозврат") Тогда
			ДокументОснование = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Документ, "ЧекККМ");
		Иначе
			ДокументОснование = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Документ, "UMC_ОснованиеВозвратаUmico");	
		КонецЕсли;
		Выборка = ПолучитьВыборкуИдентификатораЧекаUmico(ДокументОснование);
		Если Выборка.Следующий() Тогда
			ИдентификаторЧекаПродажи = Выборка.Идентификатор;
		КонецЕсли;
		Если Не ЗначениеЗаполнено(ИдентификаторЧекаПродажи) Тогда
			// Чек продажи не был зарегистрирован в Umico, поэтому сведения о возврате также передавать не нужно.
			Ответ.Результат = Истина;
			Возврат Ответ;
		КонецЕсли;
	КонецЕсли;
	
	// Если есть сведения о чеке, то перед повторной отправкой удалим предыдущие сведения.
	ОтменитьЧек(Документ);
	
	// 1. В Umico отправляются данные чека для предварительной регистрации.
	Если ЭтоПродажа Тогда
		СтруктураОтвета = ЗарегистрироватьЧекВUmico(Документ);
		ДанныеРегистрацииЧека = ОбработатьОтветПоРегистрацииЧека(СтруктураОтвета);
	Иначе
		СтруктураОтвета = ЗарегистрироватьЧекВозвратаВUmico(Документ, ДокументОснование, ИдентификаторЧекаПродажи);
		ДанныеРегистрацииЧека = ОбработатьОтветПоРегистрацииЧекаВозврата(СтруктураОтвета);
	КонецЕсли;

	// 2. Если шаг 1 пройден успешно, то будет отправлен запрос на подтверждение (оплату чека) в Umico.
	Если ДанныеРегистрацииЧека.Результат Тогда
		Идентификатор = ДанныеРегистрацииЧека.Идентификатор;
		СохранитьДанныеЧекаUmico(Документ, Идентификатор);
		Если ЭтоПродажа Тогда
			СтруктураОтвета = ЗарегистрироватьЧекВUmico(Документ, Идентификатор);
		Иначе
			СтруктураОтвета = ЗарегистрироватьЧекВозвратаВUmico(Документ, ДокументОснование, ИдентификаторЧекаПродажи,
				Идентификатор);
		КонецЕсли;
	Иначе
		Ответ.ТекстОшибки = ДанныеРегистрацииЧека.ТекстОшибки;
		Возврат Ответ;
	КонецЕсли;
	
	// 3. Шаг 2 не возвращает ответа. Для проверки статуса чека нужно выполнить отдельный запрос.
	ОтветСтатусЧека = ПолучитьСтатусЧека(Документ, Идентификатор);
	Ответ.Результат = ОтветСтатусЧека.Результат;
	Ответ.ТекстОшибки = ОтветСтатусЧека.ТекстОшибки;

	Возврат Ответ;

КонецФункции

// Отменить регистрацию чека Umico.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг, ДокументСсылка.ВозвратТоваровОтКлиента, ДокументСсылка.ЧекККМВозврат - Документ
//	ЭтоПродажа - Булево
//	
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico
Функция ОтменитьЧек(Документ) Экспорт

	Ответ = UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico();

	Выборка = ПолучитьВыборкуИдентификатораЧекаUmico(Документ);
	Если Выборка.Следующий() Тогда
		Идентификатор = Выборка.Идентификатор;
	КонецЕсли;

	Если Не ЗначениеЗаполнено(Идентификатор) Тогда
		// Чек не был зарегистрирован в Umico, поэтому отменять его не нужно.
		Ответ.Результат = Истина;
		Возврат Ответ;
	КонецЕсли;

	// 1. Отменяем чек.
	Ресурс = "/" + ПолучитьИмяРесурсаПоВидуОперации(ЭтоПродажа(Документ)) + "/" + Идентификатор;
	СтруктураОтвета = ВыполнитьHTTPЗапрос("delete", "DELETE", Ресурс);
	Если НЕ СтруктураОтвета.Результат Тогда
		Ответ.ТекстОшибки = СтруктураОтвета.ТекстОшибки;
		Возврат Ответ;
	КонецЕсли;
	
	// 2. Шаг 1 не возвращает ответа. Для проверки статуса чека нужно выполнить отдельный запрос.
	ОтветСтатусЧека = ПолучитьСтатусЧека(Документ, Идентификатор);
	Ответ.Результат = ОтветСтатусЧека.Результат;
	Ответ.ТекстОшибки = ОтветСтатусЧека.ТекстОшибки;
			
	Возврат Ответ;

КонецФункции

// Получить статус чека.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг, ДокументСсылка.ВозвратТоваровОтКлиента, ДокументСсылка.ЧекККМВозврат - Документ
//  Идентификатор - Строка - Идентификатор
// 
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураСтатусЧекаUmico
Функция ПолучитьСтатусЧека(Документ, Идентификатор = "") Экспорт
	
	Если Идентификатор = "" Тогда
		Выборка = ПолучитьВыборкуИдентификатораЧекаUmico(Документ);
		Если Выборка.Следующий() Тогда
			Идентификатор = Выборка.Идентификатор;
		КонецЕсли;

		Если Не ЗначениеЗаполнено(Идентификатор) Тогда
			// Чек не был зарегистрирован в Umico, поэтому получать его статус не нужно.
			ОтветСтатусЧека = UMC_ОбменСUmico.НоваяСтруктураСтатусЧекаUmico();
			ОтветСтатусЧека.Результат = Истина;
			Возврат ОтветСтатусЧека;
		КонецЕсли;
	КонецЕсли;
	
	КоличествоПопыток = 3;
	ИнтервалПопытки = 5; // в секундах
	Пока КоличествоПопыток > 0 Цикл

		ОтветСтатусЧека = ПроверитьСтатусЧекаUmico(Документ, ЭтоПродажа(Документ), Идентификатор);
		Если ОтветСтатусЧека <> Неопределено И Не ОтветСтатусЧека.Ожидание Тогда
			Возврат ОтветСтатусЧека;
		КонецЕсли;
		
		// Ожидание.
		ОбщегоНазначенияБТС.Пауза(ИнтервалПопытки);

		КоличествоПопыток = КоличествоПопыток - 1;

	КонецЦикла;
	
	ОтветСтатусЧека = UMC_ОбменСUmico.НоваяСтруктураСтатусЧекаUmico();
	ОтветСтатусЧека.ТекстОшибки = НСтр("ru = 'Превышено время ожидания ответа о Umico.'");
	Возврат ОтветСтатусЧека;
	
КонецФункции

// Предварительная регистрация чека Umico. Необходима для расчета суммы возврата баллами Umico.
// 
// Параметры:
//  Документ - ДокументСсылка.ВозвратТоваровОтКлиента, ДокументСсылка.ЧекККМВозврат - Документ
//	
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураДанныеРегистрацииЧекаВозвратаUmico
Функция ПредварительнаяРегистрацияЧекаПередВозвратом(Документ) Экспорт
	
	ДанныеРегистрацииЧека = UMC_ОбменСUmico.НоваяСтруктураДанныеРегистрацииЧекаВозвратаUmico();

	ИдентификаторЧекаПродажи = Неопределено;

	ДокументОснование = Неопределено;

	Если ТипЗнч(Документ) = Тип("ДокументСсылка.ЧекККМВозврат") Тогда
		ДокументОснование = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Документ, "ЧекККМ");
	Иначе
		ДокументОснование = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Документ, "UMC_ОснованиеВозвратаUmico");
	КонецЕсли;
	Выборка = ПолучитьВыборкуИдентификатораЧекаUmico(ДокументОснование);
	Если Выборка.Следующий() Тогда
		ИдентификаторЧекаПродажи = Выборка.Идентификатор;
	КонецЕсли;
	Если Не ЗначениеЗаполнено(ИдентификаторЧекаПродажи) Тогда
		// Чек продажи не был зарегистрирован в Umico, поэтому сведения о возврате также передавать не нужно.
		ДанныеРегистрацииЧека.Результат = Истина;
		Возврат ДанныеРегистрацииЧека;
	КонецЕсли;
	
	// Если есть сведения о чеке, то перед повторной отправкой удалим предыдущие сведения.
	ОтменитьЧек(Документ);
	
	// Предварительная регистрация.
	СтруктураОтвета = ЗарегистрироватьЧекВозвратаВUmico(Документ, ДокументОснование, ИдентификаторЧекаПродажи);

	ДанныеРегистрацииЧека = ОбработатьОтветПоРегистрацииЧекаВозврата(СтруктураОтвета);
	
	Если ДанныеРегистрацииЧека.Результат Тогда
		Идентификатор = ДанныеРегистрацииЧека.Идентификатор;
		СохранитьДанныеЧекаUmico(Документ, Идентификатор);
	КонецЕсли;
	
	Возврат ДанныеРегистрацииЧека;
	
КонецФункции

// // Заполняет реквизиты, необходимые для подлкючения к Umico.
// 
// Возвращаемое значение:
//  Булево - Определить параметры подключения
Функция ОпределитьПараметрыПодключения() Экспорт

	Запрос = Новый Запрос("ВЫБРАТЬ
						  |	ПараметрыПодключения.APIKey,
						  |	ПараметрыПодключения.POSID
						  |ИЗ
						  |	Справочник.UMC_ПараметрыПодключенияКUmico КАК ПараметрыПодключения
						  |ГДЕ
						  |	ВЫБОР
						  |		КОГДА &ВариантИспользования = ЗНАЧЕНИЕ(Перечисление.UMC_ВариантыИспользованияПодключенияКUmico.ДляОптовыхПродаж)
						  |			ТОГДА ПараметрыПодключения.Пользователь = &Пользователь
						  |		ИНАЧЕ ПараметрыПодключения.КассаККМ = &КассаККМ
						  |	КОНЕЦ
						  |	И ПараметрыПодключения.ВариантИспользования = &ВариантИспользования");
	Запрос.УстановитьПараметр("Пользователь", Пользователи.ТекущийПользователь());
	Запрос.УстановитьПараметр("КассаККМ", КассаККМ);
	Запрос.УстановитьПараметр("ВариантИспользования", ВариантИспользования);

	Результат = Запрос.Выполнить();

	Если Не Результат.Пустой() Тогда
		Выборка = Результат.Выбрать();
		Выборка.Следующий();
		ЗаполнитьЗначенияСвойств(ЭтотОбъект, Выборка);
		Возврат Истина;
	Иначе
		Возврат Ложь;
	КонецЕсли;

КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

#Область ОбработкаHTTPЗапросов

// Выполняет передачу HTTP-запроса на сервер Umico.
// 
// Параметры:
//  Команда - Строка - Команда
//  Метод - Строка - Метод
//  Ресурс - Строка - Ресурс
//  ТелоЗапроса - Строка - Тело запроса
//  Документ - Неопределено - Документ
// 
// Возвращаемое значение:
// 	см. UMC_ОбменСUmico.НоваяСтруктураОтветHTTPЗапроса.
Функция ВыполнитьHTTPЗапрос(Команда, Метод, Ресурс, ТелоЗапроса = "", Документ = Неопределено)

	СтруктураОтвета = UMC_ОбменСUmico.НоваяСтруктураОтветHTTPЗапроса();

	HTTPСоединение = Новый HTTPСоединение("integration-api.umico.az", , , , , , Новый ЗащищенноеСоединениеOpenSSL);

	Заголовки = Новый Соответствие;
	Заголовки.Вставить("ApiKey", APIKey);
	Заголовки.Вставить("Content-Type", "application/json; charset=utf-8");

	HTTPЗапрос = Новый HTTPЗапрос("/api/v1" + Ресурс, Заголовки);
	HTTPЗапрос.УстановитьТелоИзСтроки(ТелоЗапроса);

	Попытка

		HTTPОтвет = HTTPСоединение.ВызватьHTTPМетод(Метод, HTTPЗапрос);
		ТелоОтвета = HTTPОтвет.ПолучитьТелоКакСтроку();
		СформироватьЗаписьЖурналаЗапросовUmico(Команда, Метод, Ресурс, ТелоЗапроса, Документ, ТелоОтвета);

		Если HTTPОтвет.КодСостояния >= 200 И HTTPОтвет.КодСостояния < 300 Тогда
			СтруктураОтвета.Результат = Истина;
			СтруктураОтвета.ТелоОтвета = ТелоОтвета;
		ИначеЕсли ТелоОтвета = "{""message"":""API rate limit exceeded""}" Тогда
			// Ошибка ожидания.
			СтруктураОтвета.Ожидание = Истина;
		Иначе
			ТекстСообщения = СтрШаблон(НСтр("ru = 'Ошибка при подключении к Umico. Код статуса: %1'"),
				HTTPОтвет.КодСостояния);
			СтруктураОтвета.ТекстОшибки = ТекстСообщения;
		КонецЕсли;

	Исключение
		СтруктураОтвета.ТекстОшибки = ОписаниеОшибки();
	КонецПопытки;

	Возврат СтруктураОтвета;

КонецФункции

// Формирует запись логов в журнале.
// 
// Параметры:
//  Команда - Строка - Команда
//  Метод - Строка - Метод
//  Ресурс - Строка - Ресурс
//  ТелоЗапроса - Строка - Тело запроса
//  Документ - Неопределено - Документ
//  ТелоОтвета - Неопределено, Строка - Тело ответа
Процедура СформироватьЗаписьЖурналаЗапросовUmico(Команда, Метод, Ресурс, ТелоЗапроса, Документ, ТелоОтвета)

	ТекущийПользователь = Пользователи.ТекущийПользователь();

	ЗаписьЖурнала = Справочники.UMC_ЖурналЗапросовКUmico.СоздатьЭлемент();
	ЗаписьЖурнала.Дата = ТекущаяДатаСеанса();
	ЗаписьЖурнала.Пользователь = ТекущийПользователь;
	ЗаписьЖурнала.Команда = Команда;
	ЗаписьЖурнала.Метод = Метод;
	ЗаписьЖурнала.Ресурс = Ресурс;
	ЗаписьЖурнала.Запрос = ТелоЗапроса;
	ЗаписьЖурнала.Ответ = ТелоОтвета;
	ЗаписьЖурнала.Документ = Документ;
	ЗаписьЖурнала.Записать();

КонецПроцедуры

// Обработать ответ по сведениям о карте.
// 
// Параметры:
//  СтруктураОтвета - Структура - Структура ответа:
// 	см. UMC_ОбменСUmico.НоваяСтруктураОтветHTTPЗапроса.
// 
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураСведенияОКартеUmico.
Функция ОбработатьОтветПоСведениямОКарте(СтруктураОтвета)

	СведенияОКарте = UMC_ОбменСUmico.НоваяСтруктураСведенияОКартеUmico();

	Если Не СтруктураОтвета.Результат Или Не ЗначениеЗаполнено(СтруктураОтвета.ТелоОтвета) Тогда
		СведенияОКарте.ТекстОшибки = СтруктураОтвета.ТекстОшибки;
		Возврат СведенияОКарте;
	КонецЕсли;

	ЧтениеJSON = Новый ЧтениеJSON;
	ЧтениеJSON.УстановитьСтроку(СтруктураОтвета.ТелоОтвета);
	СтруктураJSON = ПрочитатьJSON(ЧтениеJSON); // См. UMC_ОбменСUmico.НоваяСтруктураJSONBalance

	СведенияОКарте.Результат = Истина;
	СведенияОКарте.Сумма = СтруктураJSON.available_points;

	Возврат СведенияОКарте;

КонецФункции

// Обработать ответ регистрации чека.
// 
// Параметры:
//  СтруктураОтвета - Структура - Структура ответа:
// 	см. UMC_ОбменСUmico.НоваяСтруктураОтветHTTPЗапроса.
// 
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураДанныеРегистрацииЧекаUmico.
Функция ОбработатьОтветПоРегистрацииЧека(СтруктураОтвета)

	ДанныеРегистрацииЧека = UMC_ОбменСUmico.НоваяСтруктураДанныеРегистрацииЧекаUmico();

	Если Не СтруктураОтвета.Результат Или Не ЗначениеЗаполнено(СтруктураОтвета.ТелоОтвета) Тогда
		ДанныеРегистрацииЧека.ТекстОшибки = СтруктураОтвета.ТекстОшибки;
		Возврат ДанныеРегистрацииЧека;
	КонецЕсли;

	ЧтениеJSON = Новый ЧтениеJSON;
	ЧтениеJSON.УстановитьСтроку(СтруктураОтвета.ТелоОтвета);
	СтруктураJSON = ПрочитатьJSON(ЧтениеJSON); // См. UMC_ОбменСUmico.НоваяСтруктураJSONCheckout

	ДанныеРегистрацииЧека.Результат = Истина;
	ДанныеРегистрацииЧека.Идентификатор = СтруктураJSON.order_ext_id;

	Возврат ДанныеРегистрацииЧека;

КонецФункции

// Обработать ответ регистрации чека.
// 
// Параметры:
//  СтруктураОтвета - Структура - Структура ответа:
// 	см. UMC_ОбменСUmico.НоваяСтруктураОтветHTTPЗапроса.
// 
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураДанныеРегистрацииЧекаВозвратаUmico.
Функция ОбработатьОтветПоРегистрацииЧекаВозврата(СтруктураОтвета)

	ДанныеРегистрацииЧека = UMC_ОбменСUmico.НоваяСтруктураДанныеРегистрацииЧекаВозвратаUmico();

	Если Не СтруктураОтвета.Результат Или Не ЗначениеЗаполнено(СтруктураОтвета.ТелоОтвета) Тогда
		ДанныеРегистрацииЧека.ТекстОшибки = СтруктураОтвета.ТекстОшибки;
		Возврат ДанныеРегистрацииЧека;
	КонецЕсли;

	ЧтениеJSON = Новый ЧтениеJSON;
	ЧтениеJSON.УстановитьСтроку(СтруктураОтвета.ТелоОтвета);
	СтруктураJSON = ПрочитатьJSON(ЧтениеJSON); // См. UMC_ОбменСUmico.НоваяСтруктураJSONRefund

	ДанныеРегистрацииЧека.Результат = Истина;
	ДанныеРегистрацииЧека.Идентификатор = СтруктураJSON.refund_ext_id;
	ДанныеРегистрацииЧека.СуммаБалловКВозврату = СтруктураJSON.accrued_points;

	Возврат ДанныеРегистрацииЧека;

КонецФункции

// Обработать ответ по статусу чека.
// 
// Параметры:
// СтруктураОтвета - Структура - Структура ответа:
// 	см. UMC_ОбменСUmico.НоваяСтруктураОтветHTTPЗапроса.
// Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг, ДокументСсылка.ВозвратТоваровОтКлиента, ДокументСсылка.ЧекККМВозврат - Документ
// Возвращаемое значение:
// см. UMC_ОбменСUmico.НоваяСтруктураСтатусЧекаUmico
Функция ОбработатьОтветПоСтатусуЧека(СтруктураОтвета, Документ)

	СтатусЧека = UMC_ОбменСUmico.НоваяСтруктураСтатусЧекаUmico();

	Если Не СтруктураОтвета.Результат Или Не ЗначениеЗаполнено(СтруктураОтвета.ТелоОтвета) Тогда
		СтатусЧека.ТекстОшибки = СтруктураОтвета.ТекстОшибки;
		Возврат СтатусЧека;
	КонецЕсли;

	ЧтениеJSON = Новый ЧтениеJSON;
	ЧтениеJSON.УстановитьСтроку(СтруктураОтвета.ТелоОтвета);
	СтруктураJSON = ПрочитатьJSON(ЧтениеJSON); // См. UMC_ОбменСUmico.НоваяСтруктураJSONStatus

	ОбновитьСтатусЧекаUmico(Документ, СтруктураJSON.status);

	СтатусЧека.Результат = НРег(СтруктураJSON.status) = "paid";
	СтатусЧека.Ожидание = НРег(СтруктураJSON.status) = "pending" Или НРег(СтруктураJSON.status) = "processing";

	Возврат СтатусЧека;

КонецФункции

// Сохранить данные чека Umico.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг, ДокументСсылка.ВозвратТоваровОтКлиента, ДокументСсылка.ЧекККМВозврат - Документ
//  Идентификатор - Строка - Идентификатор
Процедура СохранитьДанныеЧекаUmico(Документ, Идентификатор)

	НоваяЗапись = РегистрыСведений.UMC_ИдентификаторыЧековUmico.СоздатьМенеджерЗаписи();
	НоваяЗапись.Документ = Документ;
	НоваяЗапись.Идентификатор = Идентификатор;
	НоваяЗапись.Записать();

КонецПроцедуры

// Обновить статус чека Umico.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг, ДокументСсылка.ВозвратТоваровОтКлиента, ДокументСсылка.ЧекККМВозврат - Документ
//  Статус - Строка - Статус
Процедура ОбновитьСтатусЧекаUmico(Документ, Статус)
	
	НаборЗаписей = РегистрыСведений.UMC_ИдентификаторыЧековUmico.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Документ.Установить(Документ);
	НаборЗаписей.Прочитать();
	Если НаборЗаписей.Количество() > 0 Тогда
		НаборЗаписей[0].Статус = Статус;
		НаборЗаписей.Записать(Истина);
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ПодготовкаЗапросаКUmico

// Возвращает идентификатор чека Umico.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ,ДокументСсылка.ЧекККМВозврат,ДокументСсылка.РеализацияТоваровУслуг,ДокументСсылка.ВозвратТоваровОтКлиента
// 
// Возвращаемое значение:
// ВыборкаИзРезультатаЗапроса:
//  * Идентификатор - Строка
Функция ПолучитьВыборкуИдентификатораЧекаUmico(Документ)

	Запрос = Новый Запрос("ВЫБРАТЬ
						  |	ИдентификаторыЧековUmico.Идентификатор
						  |ИЗ
						  |	РегистрСведений.UMC_ИдентификаторыЧековUmico КАК ИдентификаторыЧековUmico
						  |ГДЕ
						  |	ИдентификаторыЧековUmico.Документ = &Документ
						  |	И ИдентификаторыЧековUmico.Идентификатор <> """"");
	Запрос.УстановитьПараметр("Документ", Документ);

	Возврат Запрос.Выполнить().Выбрать();

КонецФункции

// Формирует и отправляет запрос на создание нового чека в Umico или его подтверждение (оплату).
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг - документ продажи
//  ИдентификаторЧека - Неопределено,Строка - Идентификатор чека
// 
// Возвращаемое значение:
// 	см. UMC_ОбменСUmico.НоваяСтруктураОтветHTTPЗапроса.
Функция ЗарегистрироватьЧекВUmico(Документ, ИдентификаторЧека = Неопределено)

	ДенежныйФормат = "ЧДЦ=2; ЧРД=.; ЧН=0; ЧГ=";

	Если ТипЗнч(Документ) = Тип("ДокументСсылка.ЧекККМ") Тогда
		РеквизитыДокумента = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Документ,
		"UMC_ОплаченноБалламиUmico,UMC_НомерКартыUmico,Номер,Дата,СуммаДокумента");
		ВалютаДокумента = Константы.ВалютаРегламентированногоУчета.Получить();
	Иначе
		РеквизитыДокумента = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Документ,
		"UMC_ОплаченноБалламиUmico,UMC_НомерКартыUmico,Номер,Дата,СуммаДокумента, Валюта");
		ВалютаДокумента = РеквизитыДокумента.Валюта;		
	КонецЕсли;

	Выборка = ПолучитьВыборкуПоТоварамДокумента(Документ);

	Товары = Новый Массив; // Массив Из см. UMC_ОбменСUmico.НоваяСтруктураТоварЧекаUmico
	ПорядковыйНомер = 0;

	Пока Выборка.Следующий() Цикл

		СтруктураТовара = UMC_ОбменСUmico.НоваяСтруктураТоварЧекаUmico();

		ВидНоменклатуры = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Выборка.product, "ВидНоменклатуры"); // СправочникСсылка.ВидыНоменклатуры

		ПорядковыйНомер = ПорядковыйНомер + 1;

		ЗаполнитьЗначенияСвойств(СтруктураТовара, Выборка);

		СтруктураТовара.item_number = ПорядковыйНомер;

		СтруктураТовара.price = ФорматЧисловогоЗначения(Выборка.price, ДенежныйФормат);
		СтруктураТовара.amount_before_promo = ФорматЧисловогоЗначения(Выборка.amount_before_promo, ДенежныйФормат);
		СтруктураТовара.amount_after_promo = ФорматЧисловогоЗначения(Выборка.amount_after_promo, ДенежныйФормат);

		СтруктураТовара.product_id = Строка(Выборка.product.УникальныйИдентификатор());
		СтруктураТовара.product_group_id = Строка(ВидНоменклатуры.УникальныйИдентификатор());

		Товары.Добавить(СтруктураТовара);

	КонецЦикла;	
		
	Структура = Новый Структура;
	Если ЗначениеЗаполнено(ИдентификаторЧека) Тогда
		ОплатаКартой = Ложь;
		Если ТипЗнч(Документ) = Тип("ДокументСсылка.ЧекККМ") Тогда
			ЗапросПоОплате = Новый Запрос("ВЫБРАТЬ ПЕРВЫЕ 1
										  |	ОплатаПлатежнымиКартами.НомерСтроки
										  |ИЗ
										  |	Документ.ЧекККМ.ОплатаПлатежнымиКартами КАК ОплатаПлатежнымиКартами
										  |ГДЕ
										  |	ОплатаПлатежнымиКартами.Ссылка = &Документ");
			ЗапросПоОплате.УстановитьПараметр("Документ", Документ);
			Результат = ЗапросПоОплате.Выполнить();
			ОплатаКартой = Не Результат.Пустой();
		КонецЕсли;
		Структура.Вставить("order_ext_id", ИдентификаторЧека);
		Структура.Вставить("order_paid_at", ПолучитьДатуRFC3339(РеквизитыДокумента.Дата));
		Структура.Вставить("payment_type", ?(ОплатаКартой > 0, "cash", "card"));
	КонецЕсли;
	Структура.Вставить("order_number", РеквизитыДокумента.Номер);
	Структура.Вставить("order_created_at", ПолучитьДатуRFC3339(РеквизитыДокумента.Дата));
	Структура.Вставить("order_id", Строка(Документ.УникальныйИдентификатор()));
	Структура.Вставить("pos_ext_id", POSID);
	Структура.Вставить("pos_cashier_id", Строка(Пользователи.ТекущийПользователь()));
	Структура.Вставить("amount_before_promo", ФорматЧисловогоЗначения(РеквизитыДокумента.СуммаДокумента,
		ДенежныйФормат));
	Структура.Вставить("amount_after_promo", ФорматЧисловогоЗначения(РеквизитыДокумента.СуммаДокумента, ДенежныйФормат));
	Структура.Вставить("desc_text", "");
	Структура.Вставить("currency_code", ВалютаДокумента.Наименование);
	Структура.Вставить("loy_card_number", СтрЗаменить(СокрЛП(РеквизитыДокумента.UMC_НомерКартыUmico), " ", ""));
	Структура.Вставить("redeem_points", РеквизитыДокумента.UMC_ОплаченноБалламиUmico > 0);
	Структура.Вставить("redeem_all_points", Ложь);
	Структура.Вставить("max_redeem_points", РеквизитыДокумента.UMC_ОплаченноБалламиUmico);
	Структура.Вставить("items", Товары);

	Выборка.Сбросить();
	СохранитьНомераСтрокЧека(Документ, Выборка);
	JSON = ПолучитьJSONИзЗначения(Структура);

	Команда = ?(ИдентификаторЧека = Неопределено, "checkout", "pay");
	Ресурс = "/" + ПолучитьИмяРесурсаПоВидуОперации(ЭтоПродажа(Документ)) + "/" + Команда;

	Возврат ВыполнитьHTTPЗапрос(Команда, "POST", Ресурс, JSON, Документ);

КонецФункции

// Формирует и отправляет запрос на создание нового чека возврата в Umico или его подтверждение (оплату).
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМВозврат, ДокументСсылка.ВозвратТоваровОтКлиента - Чек ККМ
//  ДокументОснование - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг - документ продажи
//  ИдентификаторЧекаПродажи - Строка - Идентификатор чека продажи
//  ИдентификаторЧека - Неопределено,Строка - Идентификатор чека
// 
// Возвращаемое значение:
// 	см. UMC_ОбменСUmico.НоваяСтруктураОтветHTTPЗапроса.
Функция ЗарегистрироватьЧекВозвратаВUmico(Документ, ДокументОснование, ИдентификаторЧекаПродажи,
	ИдентификаторЧека = Неопределено)

	ДенежныйФормат = "ЧДЦ=2; ЧРД=.; ЧН=0; ЧГ=";

	Если ТипЗнч(Документ) = Тип("ДокументСсылка.ЧекККМ") Тогда
		РеквизитыДокумента = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Документ,
		"UMC_ОплаченноБалламиUmico,UMC_НомерКартыUmico,Номер,Дата,СуммаДокумента");
		ВалютаДокумента = Константы.ВалютаРегламентированногоУчета.Получить();
	Иначе
		РеквизитыДокумента = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Документ,
		"UMC_ОплаченноБалламиUmico,UMC_НомерКартыUmico,Номер,Дата,СуммаДокумента, Валюта");
		ВалютаДокумента = РеквизитыДокумента.Валюта;		
	КонецЕсли;

	РеквизитыДокументаОснования = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(ДокументОснование, "Номер,Дата");

	Выборка = ПолучитьВыборкуПоТоварамДокументаВозврата(Документ, ДокументОснование);

	Товары = Новый Массив; // Массив Из см. UMC_ОбменСUmico.НоваяСтруктураТоварЧекаВозвратаUmico
	ПорядковыйНомер = 0;

	Пока Выборка.Следующий() Цикл

		СтруктураТовара = UMC_ОбменСUmico.НоваяСтруктураТоварЧекаВозвратаUmico();

		ВидНоменклатуры = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Выборка.product, "ВидНоменклатуры"); // СправочникСсылка.ВидыНоменклатуры

		ПорядковыйНомер = ПорядковыйНомер + 1;

		ЗаполнитьЗначенияСвойств(СтруктураТовара, Выборка);

		СтруктураТовара.item_number = ПорядковыйНомер;

		СтруктураТовара.product_id = Строка(Выборка.product.УникальныйИдентификатор());
		СтруктураТовара.product_group_id = Строка(ВидНоменклатуры.УникальныйИдентификатор());

		Товары.Добавить(СтруктураТовара);

	КонецЦикла;

	Структура = Новый Структура;
	Если ЗначениеЗаполнено(ИдентификаторЧека) Тогда
		Структура.Вставить("refund_ext_id", ИдентификаторЧека);
		Структура.Вставить("refunded_at", ПолучитьДатуRFC3339(РеквизитыДокумента.Дата));
	КонецЕсли;
	Структура.Вставить("refund_number", РеквизитыДокумента.Номер);
	Структура.Вставить("refund_created_at", ПолучитьДатуRFC3339(РеквизитыДокумента.Дата));
	Структура.Вставить("refund_id", Строка(Документ.УникальныйИдентификатор()));
	Структура.Вставить("order_number", РеквизитыДокументаОснования.Номер);
	Структура.Вставить("order_paid_at", ПолучитьДатуRFC3339(РеквизитыДокументаОснования.Дата));
	Структура.Вставить("order_id", Строка(ДокументОснование.УникальныйИдентификатор()));
	Структура.Вставить("order_ext_id", ИдентификаторЧекаПродажи);
	Структура.Вставить("pos_ext_id", POSID);
	Структура.Вставить("pos_cashier_id", Строка(Пользователи.ТекущийПользователь()));
	Структура.Вставить("refund_amount", ФорматЧисловогоЗначения(РеквизитыДокумента.СуммаДокумента, ДенежныйФормат));
	Структура.Вставить("desc_text", "");
	Структура.Вставить("currency_code", ВалютаДокумента.Наименование);
	Структура.Вставить("loy_card_number", СтрЗаменить(СокрЛП(РеквизитыДокумента.UMC_НомерКартыUmico), " ", ""));
	Структура.Вставить("items", Товары);

	JSON = ПолучитьJSONИзЗначения(Структура);

	Команда = ?(ИдентификаторЧека = Неопределено, "refund", "refund_accept");
	Ресурс = "/" + ПолучитьИмяРесурсаПоВидуОперации(ЭтоПродажа(Документ)) + ?(ИдентификаторЧека = Неопределено, "", "/accept");

	Возврат ВыполнитьHTTPЗапрос(Команда, "POST", Ресурс, JSON, Документ);

КонецФункции

// Проверить статус чека Umico.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг, ДокументСсылка.ВозвратТоваровОтКлиента, ДокументСсылка.ЧекККМВозврат - Документ
//  ЭтоПродажа - Булево - Это продажа
//  Идентификатор - Строка - Идентификатор
// 
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураСтатусЧекаUmico
Функция ПроверитьСтатусЧекаUmico(Документ, ЭтоПродажа, Идентификатор)

	Ресурс = "/" + ПолучитьИмяРесурсаПоВидуОперации(ЭтоПродажа) + "/" + Идентификатор + "/status";

	СтруктураОтвета = ВыполнитьHTTPЗапрос("status", "GET", Ресурс, "", Документ);

	Возврат ОбработатьОтветПоСтатусуЧека(СтруктураОтвета, Документ);

КонецФункции

// Получить выборку по товарам документа.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг - Документ
// 
// Возвращаемое значение:
// ВыборкаИзРезультатаЗапроса:
//  * product - СправочникСсылка.Номенклатура
//  * quantity - Число
//  * price - Число
//  * amount_before_promo - Число
//  * amount_after_promo - Число
//  * promo_discount_pct - Число
Функция ПолучитьВыборкуПоТоварамДокумента(Документ)

	Запрос = Новый Запрос("ВЫБРАТЬ
	|	Товары.Номенклатура КАК product,
	|	СУММА(Товары.КоличествоУпаковок) КАК quantity,
	|	СУММА(Товары.Сумма) КАК amount_before_promo,
	|	СУММА(Товары.Сумма) КАК amount_after_promo,
	|	0 КАК promo_discount_pct
	|ПОМЕСТИТЬ ВТ
	|ИЗ
	|	Документ.ЧекККМ.Товары КАК Товары
	|ГДЕ
	|	Товары.Ссылка = &Документ
	|СГРУППИРОВАТЬ ПО
	|	Товары.Номенклатура
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	Товары.Номенклатура КАК product,
	|	СУММА(Товары.КоличествоУпаковок) КАК quantity,
	|	СУММА(Товары.СуммаСНДС) КАК amount_before_promo,
	|	СУММА(Товары.СуммаСНДС) КАК amount_after_promo,
	|	0 КАК promo_discount_pct
	|ИЗ
	|	Документ.РеализацияТоваровУслуг.Товары КАК Товары
	|ГДЕ
	|	Товары.Ссылка = &Документ
	|СГРУППИРОВАТЬ ПО
	|	Товары.Номенклатура
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ.product КАК product,
	|	ВТ.quantity КАК quantity,
	|	ВТ.amount_before_promo КАК amount_before_promo,
	|	ВТ.amount_after_promo КАК amount_after_promo,
	|	ВТ.promo_discount_pct КАК promo_discount_pct,
	|	ВЫБОР
	|		КОГДА ВТ.quantity > 0
	|			ТОГДА ВЫРАЗИТЬ(ВТ.amount_before_promo / ВТ.quantity КАК ЧИСЛО(15, 2))
	|		ИНАЧЕ 0
	|	КОНЕЦ КАК price
	|ИЗ
	|	ВТ КАК ВТ");
	Запрос.УстановитьПараметр("Документ", Документ);

	Возврат Запрос.Выполнить().Выбрать();

КонецФункции

// Получить выборку по товарам документа возврата.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМВозврат, ДокументСсылка.ВозвратТоваровОтКлиента - Документ
//  ДокументОснование - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг - Документ продажи
// 
// Возвращаемое значение:
// ВыборкаИзРезультатаЗапроса:
//  * product - СправочникСсылка.Номенклатура
//  * quantity - Число
//  * refund_amount - Число
//  * order_item_number - Число
Функция ПолучитьВыборкуПоТоварамДокументаВозврата(Документ, ДокументОснование)

	Запрос = Новый Запрос("ВЫБРАТЬ
	|	Товары.Номенклатура КАК product,
	|	СУММА(Товары.КоличествоУпаковок) КАК quantity,
	|	СУММА(Товары.Сумма) КАК refund_amount
	|ПОМЕСТИТЬ ВТ
	|ИЗ
	|	Документ.ЧекККМВозврат.Товары КАК Товары
	|ГДЕ
	|	Товары.Ссылка = &Документ
	|СГРУППИРОВАТЬ ПО
	|	Товары.Номенклатура
	|
	|ОБЪЕДИНИТЬ ВСЕ
	|
	|ВЫБРАТЬ
	|	Товары.Номенклатура КАК product,
	|	СУММА(Товары.КоличествоУпаковок) КАК quantity,
	|	СУММА(Товары.СуммаСНДС) КАК refund_amount
	|ИЗ
	|	Документ.ВозвратТоваровОтКлиента.Товары КАК Товары
	|ГДЕ
	|	Товары.Ссылка = &Документ
	|СГРУППИРОВАТЬ ПО
	|	Товары.Номенклатура
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ.product КАК product,
	|	ВТ.quantity КАК quantity,
	|	ВТ.refund_amount КАК refund_amount,
	|	UMC_НомераСтрокЧековUmico.ПорядковыйНомер КАК order_item_number
	|ИЗ
	|	ВТ КАК ВТ
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.UMC_НомераСтрокЧековUmico КАК UMC_НомераСтрокЧековUmico
	|		ПО UMC_НомераСтрокЧековUmico.Документ = &ДокументОснование
	|		И ВТ.product = UMC_НомераСтрокЧековUmico.Номенклатура");
	Запрос.УстановитьПараметр("Документ", Документ);
	Запрос.УстановитьПараметр("ДокументОснование", ДокументОснование);

	Возврат Запрос.Выполнить().Выбрать();

КонецФункции

// Функция возвращает имя ресурса строки URL.
// 
// Параметры:
//  ЭтоПродажа - Булево
// 
// Возвращаемое значение:
//  Строка - Получить имя ресурса по виду операции
Функция ПолучитьИмяРесурсаПоВидуОперации(ЭтоПродажа)

	Возврат ?(ЭтоПродажа, "orders", "refunds");

КонецФункции

// Процедура сохраняет данные о строках чека продажи.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг - Документ
//  Выборка - ВыборкаИзРезультатаЗапроса - Выборка:
// * product - СправочникСсылка.Номенклатура -
// * quantity - Число -
// * price - Число -
// * amount_before_promo - Число -
// * amount_after_promo - Число -
// * promo_discount_pct - Число -
Процедура СохранитьНомераСтрокЧека(Документ, Выборка)

	НаборЗаписей = РегистрыСведений.UMC_НомераСтрокЧековUmico.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Документ.Установить(Документ);
	ПорядковыйНомер = 0;
	Пока Выборка.Следующий() Цикл
		ПорядковыйНомер = ПорядковыйНомер + 1;
		НоваяЗапись = НаборЗаписей.Добавить();
		НоваяЗапись.Документ = Документ;
		НоваяЗапись.Номенклатура = Выборка.product;
		НоваяЗапись.ПорядковыйНомер = ПорядковыйНомер;
	КонецЦикла;

	НаборЗаписей.Записать(Истина);

КонецПроцедуры

#КонецОбласти

#Область Прочее

// Это продажа.
// 
// Параметры:
//  Документ - ДокументСсылка.ЧекККМ, ДокументСсылка.РеализацияТоваровУслуг, ДокументСсылка.ВозвратТоваровОтКлиента, ДокументСсылка.ЧекККМВозврат - Документ
// 
// Возвращаемое значение:
//  Булево - Это продажа
Функция ЭтоПродажа(Документ)
	Возврат ТипЗнч(Документ) = Тип("ДокументСсылка.ЧекККМ") Или ТипЗнч(Документ) = Тип(
		"ДокументСсылка.РеализацияТоваровУслуг");
КонецФункции

// Функция используется для правильного форматирования числовых значений.
// 
// Параметры:
//  Значение - Число
//  Формат - Строка - Формат
// 
// Возвращаемое значение:
//  Строка - формат числового значения
Функция ФорматЧисловогоЗначения(Значение, Формат)

	Возврат "###" + Формат(Значение, Формат) + "###";

КонецФункции

// Функция преобразует дату в строку формата RFC 3339.
// 
// Параметры:
//  Дата - Дата
// 
// Возвращаемое значение:
//  Строка - Получить дату RFC3339
Функция ПолучитьДатуRFC3339(Дата)

	Возврат Формат(УниверсальноеВремя(Дата), "ДФ=yyyy-MM-ddTHH:mm:ss.88") + СтрЗаменить(ПредставлениеЧасовогоПояса(
		ЧасовойПояс()), "GMT", "");

КонецФункции

// Функция преобразует значение в JSON
// 
// Параметры:
//  Значение - Структура
// 
// Возвращаемое значение:
//  Строка - JSON строка
Функция ПолучитьJSONИзЗначения(Значение)

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON, Значение);

	JSON = ЗаписьJSON.Закрыть();

	// Числовые значения всегда должны быть с точность в 2 знака, поэтому для удобства они были введены строкой,
	// обрамленной символом ###.
	JSON = СтрЗаменить(JSON, "###""", "");
	JSON = СтрЗаменить(JSON, """###", "");

	Возврат JSON;

КонецФункции

#КонецОбласти

#КонецОбласти

#КонецЕсли