// @strict-types

#Область ОбработчикиСобытий

&НаКлиенте
Процедура ОбработкаКоманды(ПараметрКоманды, ПараметрыВыполненияКоманды)

	ПараметрыОповещения = Новый Структура("Документ", ПараметрКоманды);
	ОписаниеОповещения = Новый ОписаниеОповещения("ПослеЗакрытияВопроса", ЭтотОбъект, ПараметрыОповещения);
	ПоказатьВопрос(ОписаниеОповещения, НСтр("ru = 'Документ будет зарегистрирован в Umico. Продолжить?'"), РежимДиалогаВопрос.ДаНет);
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// После закрытия вопроса.
// 
// Параметры:
//  Результат - КодВозвратаДиалога - ответ на вопрос
//  ДополнительныеПараметры - Структура - дополнительные параметры:
//	* Документ - ДокументСсылка.ЧекККМ,ДокументСсылка.ЧекККМВозврат,ДокументСсылка.РеализацияТоваровУслуг,ДокументСсылка.ВозвратТоваровОтКлиента
&НаКлиенте
Процедура ПослеЗакрытияВопроса(Результат, ДополнительныеПараметры) Экспорт
 
 	Документ = ДополнительныеПараметры.Документ;

	Если Результат = КодВозвратаДиалога.Нет Тогда
		Возврат;
	КонецЕсли;

	Ответ = ЗарегистрироватьЧекВUmico(Документ);
	Если Ответ.Результат Тогда
		
		ТекстСообщения = НСтр("ru = 'Чек успешно зарегистрирован в Umico.'");
		ПоказатьОповещениеПользователя(ТекстСообщения,,, БиблиотекаКартинок.Успешно32);
		
	Иначе
		
		Если ЗначениеЗаполнено(Ответ.ТекстОшибки) Тогда
			ТекстСообщения = СтрШаблон(НСтр(
				"ru = 'Не удалось передать сведения о документе в Umico по причине - %1.'"),
				Ответ.ТекстОшибки);
		Иначе
			ТекстСообщения = НСтр("ru = 'Не удалось передать сведения о документе в Umico.'");
		КонецЕсли;
		
		ОбщегоНазначенияКлиент.СообщитьПользователю(ТекстСообщения);
		
	КонецЕсли;

КонецПроцедуры

&НаСервере
Функция ЗарегистрироватьЧекВUmico(Документ)
	
	ОбработкаОбменаСUmico = Обработки.UMC_ОбменСUmico.Создать();
	
	Если ТипЗнч(Документ) = Тип("ДокументСсылка.ЧекККМ") Или ТипЗнч(Документ) = Тип("ДокументСсылка.ЧекККМВозврат") Тогда
		ОбработкаОбменаСUmico.КассаККМ = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Документ, "КассаККМ");
		ОбработкаОбменаСUmico.ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж;
	Иначе
		ОбработкаОбменаСUmico.ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляОптовыхПродаж;	
	КонецЕсли;
	
	Если ОбработкаОбменаСUmico.ОпределитьПараметрыПодключения() Тогда
		Возврат ОбработкаОбменаСUmico.ЗарегистрироватьЧек(Документ);
	Иначе
		Ответ = UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico();
		Ответ.ТекстОшибки = UMC_ОбменСUmico.ПолучитьТекстОшибкиНеОпределеныПараметрыПодключения();
		Возврат Ответ;
	КонецЕсли;
	
КонецФункции

#КонецОбласти
