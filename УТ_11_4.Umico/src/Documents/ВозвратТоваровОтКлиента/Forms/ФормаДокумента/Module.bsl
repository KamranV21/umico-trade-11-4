// @strict-types

#Область ОбработчикиСобытийФормы

&НаСервере
Процедура UMC_ПриСозданииНаСервереПосле(Отказ, СтандартнаяОбработка)
	
	UMC_ОбменСUmico.ПолучитьСтатусОбменаСUmico(ЭтотОбъект, Объект.Ссылка);
	
КонецПроцедуры

&НаКлиенте
Процедура UMC_ОбработкаОповещенияПосле(ИмяСобытия, Параметр, Источник)
	
	Если ИмяСобытия = "UMC_ИзменениеСостоянияЧека" И Параметр = Объект.Ссылка Тогда
		UMC_ПолучитьСтатусОбменаСUmico();
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиСобытийЭлементовШапкиФормы

&НаКлиенте
Процедура UMC_UMC_ОснованиеВозвратаUmicoПриИзмененииПосле(Элемент)
	
	UMC_ЗаполнитьРеквизитыUmico();
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиКомандФормы

&НаКлиенте
Процедура UMC_UMC_СписатьЗадолженностьПоUmicoПосле(Команда)
	
	UMC_Структура = UMC_ОбменСUmicoВызовСервера.НоваяСтруктураЗаполненияСписания();
	UMC_Структура.Основание = Объект.Ссылка;
	UMC_Структура.СписаниеЗаСчетUmico = Истина;
	
	UMC_ПараметрыФормы = Новый Структура;
	UMC_ПараметрыФормы.Вставить("Основание", UMC_Структура);
	
	ОткрытьФорму("Документ.СписаниеЗадолженности.Форма.ФормаДокумента", UMC_ПараметрыФормы);
	
КонецПроцедуры

&НаКлиенте
Процедура UMC_UMC_РассчитатьСуммуОплатыБалламиUmicoПосле(Команда)
	
	UMC_РассчитатьСуммуОплатыБалламиUmicoНаСервере();
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаСервере
Процедура UMC_ПолучитьСтатусОбменаСUmico()
	
	UMC_ОбменСUmicoВызовСервера.ПолучитьСтатусОбменаСUmico(ЭтотОбъект, Объект.Ссылка);	
	
КонецПроцедуры

&НаСервере
Процедура UMC_ЗаполнитьРеквизитыUmico()
	
	UMC_Значение = РеквизитФормыВЗначение("Объект");
	UMC_Значение.UMC_ЗаполнитьРеквизитыUmicoНаОсновании();
	ЗначениеВРеквизитФормы(UMC_Значение, "Объект");
	
КонецПроцедуры

&НаСервере
Процедура UMC_РассчитатьСуммуОплатыБалламиUmicoНаСервере()
	
	Если ЗначениеЗаполнено(Объект.UMC_НомерКартыUmico) Тогда
		UMC_ДанныеПредварительнойРегистрации = UMC_ПолучитьСуммуОплатыБалламиUmico();
		Если UMC_ДанныеПредварительнойРегистрации.Результат Тогда
			Объект.UMC_ОплаченноБалламиUmico = UMC_ДанныеПредварительнойРегистрации.СуммаБалловКВозврату;
		Иначе
			UMC_ТекстПредупреждения = СтрШаблон(НСтр(
				"ru = 'ВНИМАНИЕ! Не удалось получить предварительные данные для расчета возвращаемой суммы на карту Umico! %1'"),
				UMC_ДанныеПредварительнойРегистрации.ТекстОшибки);
			ОбщегоНазначения.СообщитьПользователю(UMC_ТекстПредупреждения);
		КонецЕсли;
	КонецЕсли;
	
КонецПроцедуры

// UMC получить сумму оплаты баллами Umico.
// 
// Возвращаемое значение:
//  см. UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico
&НаСервере
Функция UMC_ПолучитьСуммуОплатыБалламиUmico()
	
	UMC_ОбработкаОбменаСUmico = Обработки.UMC_ОбменСUmico.Создать();
	UMC_ОбработкаОбменаСUmico.ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляОптовыхПродаж;

	Если UMC_ОбработкаОбменаСUmico.ОпределитьПараметрыПодключения() Тогда

		Возврат UMC_ОбработкаОбменаСUmico.ПредварительнаяРегистрацияЧекаПередВозвратом(Объект.Ссылка);
		
	Иначе

		UMC_Ответ = UMC_ОбменСUmico.НоваяСтруктураРезультатРегистрацииЧекаВUmico();
		UMC_Ответ.ТекстОшибки = UMC_ОбменСUmico.ПолучитьТекстОшибкиНеОпределеныПараметрыПодключения();
		Возврат UMC_Ответ;
		
	КонецЕсли;
	
КонецФункции

#КонецОбласти