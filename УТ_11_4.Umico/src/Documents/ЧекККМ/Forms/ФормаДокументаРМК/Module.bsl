// @strict-types
#Область ОбработчикиКомандФормы

&НаКлиенте
Процедура UMC_UMC_ВвестиКартуUmicoПосле(Команда)

	UMC_ПараметрыФормы = Новый Структура;
	UMC_ПараметрыФормы.Вставить("РежимВвода", 2);
	UMC_ПараметрыФормы.Вставить("НомерКарты", Объект.UMC_НомерКартыUmico);
	UMC_ПараметрыФормы.Вставить("КассаККМ", Объект.КассаККМ);
	UMC_ПараметрыФормы.Вставить("ВариантИспользования", ПредопределенноеЗначение(
		"Перечисление.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж"));

	ОткрытьФорму("Обработка.UMC_ОбменСUmico.Форма.ВводКартыUmico", UMC_ПараметрыФормы, ЭтотОбъект, , , ,
		Новый ОписаниеОповещения("UMC_ВводКартыUmicoЗавершение", ЭтотОбъект),
		РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

КонецПроцедуры

&НаКлиенте
Процедура UMC_UMC_ОчиститьКартуUmicoПосле(Команда)

	Объект.UMC_НомерКартыUmico = "";
	Объект.UMC_ОплаченноБалламиUmico = 0;

	UMC_УстановитьВидимостьНомераКартыUmico();

КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&После("НастроитьРМК")
&НаСервере
Процедура UMC_НастроитьРМК()
	
	// Смешанная оплата доступна всегда при использовании расширения обмена с Umico.
	Элементы.СмешаннаяОплата.Видимость = Истина;
	
	UMC_ЭлементыНаПерегруппировку = Новый Массив; // Массив из КнопкаФормы
	UMC_ЭлементыНаПерегруппировку.Добавить(Элементы.БыстрыеТовары);
	UMC_ЭлементыНаПерегруппировку.Добавить(Элементы.РассчитатьСкидки);
	
	Для Каждого Подгруппа Из Элементы.ГруппаНижняяКоманднаяПанельКонтекстныеКоманды.ПодчиненныеЭлементы Цикл
		Для Каждого Элемент Из Подгруппа.ПодчиненныеЭлементы Цикл
			UMC_ЭлементыНаПерегруппировку.Добавить(Элемент);
		КонецЦикла;
	КонецЦикла;
	
	UMC_ЭлементыНаПерегруппировку.Добавить(Элементы.ОплатитьНаличными);
	UMC_ЭлементыНаПерегруппировку.Добавить(Элементы.ОплатитьКартой);
	
	UMC_ЭлементыНаПерегруппировку.Добавить(Элементы.СмешаннаяОплата);
	UMC_ЭлементыНаПерегруппировку.Добавить(Элементы.ОплатитьПодарочнымСертификатом);
	
	РозничныеПродажи.ПерегруппироватьКнопкиФормы(ЭтотОбъект, UMC_ЭлементыНаПерегруппировку);
	
	РозничныеПродажи.НастроитьКомандыПечати(ЭтотОбъект);
	
КонецПроцедуры

&Вместо("ИнформацияОбОплате")
&НаКлиентеНаСервереБезКонтекста
// ИзменениеИКонтроль не используется по причине нестабильности.
//@skip-check extension-variable-prefix
//@skip-check property-return-type
Функция UMC_ИнформацияОбОплате(Форма)

	Форма.СуммаДокумента = ЦенообразованиеКлиентСервер.ПолучитьСуммуДокумента(Форма.Объект.Товары, Форма.Объект.ЦенаВключаетНДС);
	
	СуммаСкидки = Форма.Объект.Товары.Итог("СуммаРучнойСкидки")
	            + Форма.Объект.Товары.Итог("СуммаАвтоматическойСкидки");
	СуммаСкидкиБонусныеБаллы = Форма.Объект.Товары.Итог("СуммаБонусныхБалловКСписаниюВВалюте");
	
	Если Форма.Объект.ЦенаВключаетНДС Тогда
		СуммаБезСкидки = Форма.СуммаДокумента + СуммаСкидки + СуммаСкидкиБонусныеБаллы;
	Иначе
		СуммаБезСкидки = Форма.СуммаДокумента - Форма.Объект.Товары.Итог("СуммаНДС") + СуммаСкидки + СуммаСкидкиБонусныеБаллы;
	КонецЕсли;
	
	СуммаКОплате = СуммаБезСкидки - СуммаСкидки;
	
	ИнформацияОбОплате = Новый Структура;
	ИнформацияОбОплате.Вставить("Документ",              Форма.Объект.Ссылка);
	
	ИнформацияОбОплате.Вставить("Наличные",              Форма.Объект.ПолученоНаличными);
	ИнформацияОбОплате.Вставить("ПлатежныеКарты",        Форма.Объект.ОплатаПлатежнымиКартами.Итог("Сумма"));
	ИнформацияОбОплате.Вставить("ПодарочныеСертификаты", Форма.Объект.ПодарочныеСертификаты.Итог("Сумма"));
	ИнформацияОбОплате.Вставить("БонусныеБаллы",         СуммаСкидкиБонусныеБаллы);
	
	ИнформацияОбОплате.Вставить("СуммаДокумента",        Форма.СуммаДокумента);
	ИнформацияОбОплате.Вставить("СуммаБезСкидки",        СуммаБезСкидки);
	ИнформацияОбОплате.Вставить("СуммаКОплате",          СуммаКОплате);
	ИнформацияОбОплате.Вставить("СуммаСкидки",           СуммаСкидки);
	ИнформацияОбОплате.Вставить("ИтогоОплачено",         ИнформацияОбОплате.Наличные + ИнформацияОбОплате.ПлатежныеКарты + ИнформацияОбОплате.ПодарочныеСертификаты + ИнформацияОбОплате.БонусныеБаллы);
	
	ИнформацияОбОплате.Вставить("ДоступныеВидыОплаты", ДоступныеВидыОплаты(Форма));
	
	//#Вставка
	ИнформацияОбОплате
		.Вставить("БаллыUmico", Форма.Объект.UMC_ОплаченноБалламиUmico);
		ИнформацияОбОплате.Вставить("ИтогоОплачено", ИнформацияОбОплате.Наличные + ИнформацияОбОплате.ПлатежныеКарты
		+ ИнформацияОбОплате.ПодарочныеСертификаты + ИнформацияОбОплате.БонусныеБаллы + ИнформацияОбОплате.БаллыUmico);
	//#КонецВставки
	
	Возврат ИнформацияОбОплате;

КонецФункции

// Параметры:
//  ИзмененныеДанныеЗаписаны - Булево
//  ПараметрыЗавершения - Неопределено,Структура:
//	* ПолученоНаличными - Число
&НаКлиенте
Процедура UMC_ДобавитьОплатуБалламиUmico(ИзмененныеДанныеЗаписаны, ПараметрыЗавершения) Экспорт

	Если Не ИзмененныеДанныеЗаписаны Тогда
		Возврат;
	КонецЕсли;

	Если ПараметрыЗавершения <> Неопределено Тогда
		Объект.ПолученоНаличными = ПараметрыЗавершения.ПолученоНаличными;
	КонецЕсли;

	UMC_ПараметрыФормы = Новый Структура;
	UMC_ПараметрыФормы.Вставить("НомерКарты", Объект.UMC_НомерКартыUmico);
	UMC_ПараметрыФормы.Вставить("КассаККМ", Объект.КассаККМ);
	UMC_ПараметрыФормы.Вставить("ВариантИспользования", ПредопределенноеЗначение(
		"Перечисление.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж"));

	ОткрытьФорму(
		"Обработка.UMC_ОбменСUmico.Форма.ВводКартыUmico", UMC_ПараметрыФормы, ЭтотОбъект, , , ,
		Новый ОписаниеОповещения("UMC_ДобавитьОплатуБалламиUmicoЗавершение", ЭтотОбъект, ПараметрыЗавершения),
		РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

КонецПроцедуры

// UMC добавить оплату баллами Umico завершение.
// 
// Параметры:
//  Результат см. UMC_ОбменСUmico.НоваяСтруктураРезультатВводаКартыUmico
//  ДополнительныеПараметры - Структура
&НаКлиенте
Процедура UMC_ДобавитьОплатуБалламиUmicoЗавершение(Результат, ДополнительныеПараметры) Экспорт

	Если Не ЗначениеЗаполнено(Результат) Тогда
		ОбработатьДобавлениеОплаты(ДополнительныеПараметры);
		Возврат;
	КонецЕсли;

	UMC_ПрименитьОплатуБалламиUmico(Результат);

	ОбработатьДобавлениеОплаты(ДополнительныеПараметры);

КонецПроцедуры

// UMC применить оплату баллами Umico.
// 
// Параметры:
//  Результат - Структура,Неопределено - Результат:
// 	см. UMC_ОбменСUmico.НоваяСтруктураРезультатВводаКартыUmico
&НаСервере
Процедура UMC_ПрименитьОплатуБалламиUmico(Результат)

	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;

	Объект.UMC_НомерКартыUmico = Результат.НомерКарты;
	Объект.UMC_ОплаченноБалламиUmico = Результат.Сумма;

	UMC_РезультатЗаписи = ЗаписатьНаСервере();
	Если Не UMC_РезультатЗаписи Тогда
		UMC_ТекстСообщения = НСтр("ru = 'После изменения оплаты баллами Umico не удалось сохранить документ.'");
		ОбщегоНазначения.СообщитьПользователю(UMC_ТекстСообщения);
	КонецЕсли;

	UMC_УстановитьВидимостьНомераКартыUmico();

КонецПроцедуры

// UMC ввод карты Umico завершение.
// 
// Параметры:s
//  Результат см. UMC_ОбменСUmico.НоваяСтруктураРезультатВводаКартыUmico
//  ДополнительныеПараметры - Структура
&НаКлиенте
Процедура UMC_ВводКартыUmicoЗавершение(Результат, ДополнительныеПараметры) Экспорт

	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;

	Объект.UMC_НомерКартыUmico = Результат.НомерКарты;
	Объект.UMC_ОплаченноБалламиUmico = Результат.Сумма;

	UMC_УстановитьВидимостьНомераКартыUmico();

КонецПроцедуры

&НаСервере
Процедура UMC_УстановитьВидимостьНомераКартыUmico()

	Элементы.UMC_ИнформацияUmico.Видимость = ЗначениеЗаполнено(Объект.UMC_НомерКартыUmico);

КонецПроцедуры

&После("ПриСозданииЧека")
&НаСервере
Процедура UMC_ПриСозданииЧека()

	UMC_УстановитьВидимостьНомераКартыUmico();

КонецПроцедуры

// UMC пробить чек завершение.
// 
// Параметры:
//  Результат - Структура - Результат:
//  * ВыполненаОперацияНаУстройстве - Булево
//  * ИзмененныеДанныеЗаписаны - Булево
//  ДополнительныеПараметры  - Структура, Неопределено - Дополнительные параметры
&После("ПробитьЧекЗавершение")
&НаКлиенте
Процедура UMC_ПробитьЧекЗавершение(Результат, ДополнительныеПараметры) Экспорт

	Если Результат.ВыполненаОперацияНаУстройстве И Результат.ИзмененныеДанныеЗаписаны И ЗначениеЗаполнено(
		Объект.UMC_НомерКартыUmico) Тогда

		UMC_ЗапуститьПередачуИнформацииОЧекеВUmico();	

	КонецЕсли;

КонецПроцедуры

&НаКлиенте
Процедура UMC_ЗапуститьПередачуИнформацииОЧекеВUmico()
	
	UMC_СтруктураОтвета = UMC_ПередатьИнформациюОЧекеВUmico();
	Если Не UMC_СтруктураОтвета.Результат Тогда
		
		Если ЗначениеЗаполнено(UMC_СтруктураОтвета.ТекстОшибки) Тогда
			UMC_ТекстСообщения = СтрШаблон(НСтр(
				"ru = 'Не удалось передать сведения о документе в Umico по причине - %1. Повторить попытку?'"),
				UMC_СтруктураОтвета.ТекстОшибки);
		Иначе
			UMC_ТекстСообщения = НСтр("ru = 'Не удалось передать сведения о документе в Umico. Повторить попытку?'");
		КонецЕсли;
		
		ПоказатьВопрос(Новый ОписаниеОповещения("UMC_ПробитьЧекОшибкаЗавершение", ЭтотОбъект), UMC_ТекстСообщения,
			РежимДиалогаВопрос.ДаНет, 10);
			
	КонецЕсли;
	
КонецПроцедуры

// Передает информацию о чеке в Umico.
// 
// Возвращаемое значение:
// см. UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico
&НаСервере
Функция UMC_ПередатьИнформациюОЧекеВUmico()

	UMC_ОбработкаОбменаСUmico = Обработки.UMC_ОбменСUmico.Создать();
	UMC_ОбработкаОбменаСUmico.КассаККМ = Объект.КассаККМ;
	UMC_ОбработкаОбменаСUmico.ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж;

	Если UMC_ОбработкаОбменаСUmico.ОпределитьПараметрыПодключения() Тогда

		Возврат UMC_ОбработкаОбменаСUmico.ЗарегистрироватьЧек(Объект.Ссылка);

	Иначе

		UMC_Ответ = UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico();
		UMC_Ответ.ТекстОшибки = UMC_ОбменСUmico.ПолучитьТекстОшибкиНеОпределеныПараметрыПодключения();
		Возврат UMC_Ответ;

	КонецЕсли;

КонецФункции

// UMC пробить чек ошибка завершение.
// 
// Параметры:
//  Результат - КодВозвратаДиалога - Результат
//  ДополнительныеПараметры - Структура, Неопределено - Дополнительные параметры
&НаКлиенте
Процедура UMC_ПробитьЧекОшибкаЗавершение(Результат, ДополнительныеПараметры) Экспорт

	Если Результат = КодВозвратаДиалога.Да Тогда
		UMC_ЗапуститьПередачуИнформацииОЧекеВUmico();
	КонецЕсли;

КонецПроцедуры

#КонецОбласти