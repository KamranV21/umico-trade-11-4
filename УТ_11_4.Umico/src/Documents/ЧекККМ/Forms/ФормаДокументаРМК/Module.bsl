
#Область ОбработчикиКомандФормы

&НаКлиенте
Процедура UMC_ВвестиКартуUmicoПосле(Команда)

	UMC_ПараметрыФормы = Новый Структура;
	UMC_ПараметрыФормы.Вставить("РежимВвода", 2);
	UMC_ПараметрыФормы.Вставить("КассаККМ", Объект.КассаККМ);
	UMC_ПараметрыФормы.Вставить("ВариантИспользования", ПредопределенноеЗначение(
		"Перечисление.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж"));

	ОткрытьФорму("Обработка.UMC_ОбменСUmico.Форма.ВводСчетаUmcio", UMC_ПараметрыФормы, ЭтотОбъект, , , ,
		Новый ОписаниеОповещения("UMC_ВводСчетаUmicoЗавершение", ЭтотОбъект),
		РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&ИзменениеИКонтроль("ИнформацияОбОплате")
&НаКлиентеНаСервереБезКонтекста
//@skip-check extension-variable-prefix
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

	#Вставка
		ИнформацияОбОплате.Вставить("БаллыUmico", Форма.Объект.UMC_ПолученоБонусамиUmico);
		ИнформацияОбОплате.Вставить("ИтогоОплачено", ИнформацияОбОплате.Наличные + ИнформацияОбОплате.ПлатежныеКарты
			+ ИнформацияОбОплате.ПодарочныеСертификаты + ИнформацияОбОплате.БонусныеБаллы
			+ ИнформацияОбОплате.БаллыUmico);
	#КонецВставки

	Возврат ИнформацияОбОплате;

КонецФункции

// Параметры:
//  ИзмененныеДанныеЗаписаны - Булево
//  ПараметрыЗавершения - Неопределено,Структура
&НаКлиенте
Процедура UMC_ДобавитьОплатуБалламиUmico(ИзмененныеДанныеЗаписаны, ПараметрыЗавершения) Экспорт
	
	Если Не ИзмененныеДанныеЗаписаны Тогда
		Возврат;
	КонецЕсли;
	
	Если ПараметрыЗавершения <> Неопределено Тогда
		Объект.ПолученоНаличными = ПараметрыЗавершения.ПолученоНаличными;
	КонецЕсли;
	
	UMC_ПараметрыФормы = Новый Структура;
	UMC_ПараметрыФормы.Вставить("НомерСчета", Объект.UMC_НомерСчетаUmico);
	UMC_ПараметрыФормы.Вставить("КассаККМ", Объект.КассаККМ);
	UMC_ПараметрыФормы.Вставить("ВариантИспользования", ПредопределенноеЗначение(
		"Перечисление.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж"));
	
	ОткрытьФорму(
		"Обработка.UMC_ОбменСUmico.Форма.ВводСчетаUmcio",
		UMC_ПараметрыФормы,
		ЭтотОбъект,,,,
		Новый ОписаниеОповещения("UMC_ДобавитьОплатуБалламиUmicoЗавершение", ЭтотОбъект, ПараметрыЗавершения),
		РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);
	
КонецПроцедуры

// UMC добавить оплату баллами umico завершение.
// 
// Параметры:
//  Результат см. UMC_ОбменСUmico.НоваяСтруктураРезультатВводаСчетUmcio
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

// UMC ввод счета umico завершение.
// 
// Параметры:
//  Результат см. UMC_ОбменСUmico.НоваяСтруктураРезультатВводаСчетUmcio
//  ДополнительныеПараметры - Структура
&НаКлиенте
Процедура UMC_ВводСчетаUmicoЗавершение(Результат, ДополнительныеПараметры) Экспорт
	
	UMC_ПрименитьОплатуБалламиUmico(Результат);
		
КонецПроцедуры

// UMC применить оплату баллами umico.
// 
// Параметры:
//  Результат - Структура - Результат:
// 	см. UMC_ОбменСUmico.НоваяСтруктураРезультатВводаСчетUmcio
&НаСервере
Процедура UMC_ПрименитьОплатуБалламиUmico(Результат)
	
	Объект.UMC_НомерСчетаUmico = Результат.НомерСчета;
	Объект.UMC_ОплаченноБалламиUmico = Результат.Сумма;
	
	UMC_РезультатЗаписи = ЗаписатьНаСервере();
	Если НЕ UMC_РезультатЗаписи Тогда
		UMC_ТекстСообщения = НСтр("ru = 'После изменения оплаты баллами Umico не удалось сохранить документ.'");
		ОбщегоНазначения.СообщитьПользователю(UMC_ТекстСообщения);
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти