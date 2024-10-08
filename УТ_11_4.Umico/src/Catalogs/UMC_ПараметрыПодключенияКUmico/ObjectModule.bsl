// @strict-types

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ОбработчикиСобытий

// Обработка проверки заполнения.
// 
// Параметры:
//  Отказ - Булево - Отказ
//  ПроверяемыеРеквизиты - Массив из Строка - Проверяемые реквизиты
Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	
	Если ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж Тогда
		ПроверяемыеРеквизиты.Добавить("КассаККМ");
	Иначе
		ПроверяемыеРеквизиты.Добавить("Пользователь");
	КонецЕсли; 
	
КонецПроцедуры

Процедура ПередЗаписью(Отказ)
	
	Если ОбменДанными.Загрузка = Истина Тогда
		Возврат;
	КонецЕсли;
	
	Если ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж Тогда
		Пользователь = Справочники.Пользователи.ПустаяСсылка();
	Иначе
		КассаККМ = Справочники.КассыККМ.ПустаяСсылка();
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#КонецЕсли
