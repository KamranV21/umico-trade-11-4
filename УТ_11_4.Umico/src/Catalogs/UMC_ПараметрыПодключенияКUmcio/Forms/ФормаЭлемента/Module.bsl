// @strict-types

#Область ОбработчикиСобытийФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	УстановитьВидимость();
	СформироватьПодсказкуПоНаименованию();
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиСобытийЭлементовШапкиФормы

&НаКлиенте
Процедура ВариантИспользованияПриИзменении(Элемент)
	
	УстановитьВидимость();
	СформироватьПодсказкуПоНаименованию();
	
КонецПроцедуры

&НаКлиенте
Процедура КассаККМПриИзменении(Элемент)
	
	СформироватьПодсказкуПоНаименованию();
	
КонецПроцедуры

&НаКлиенте
Процедура ПользовательПриИзменении(Элемент)
	
	СформироватьПодсказкуПоНаименованию();
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаСервере
Процедура УстановитьВидимость()
	
	Если Объект.ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж Тогда
		Элементы.КассаККМ.Видимость = Истина;
		Элементы.Пользователь.Видимость = Ложь;
	Иначе
		Элементы.КассаККМ.Видимость = Ложь;
		Элементы.Пользователь.Видимость = Истина;
	КонецЕсли;
	
КонецПроцедуры

&НаСервере
Процедура СформироватьПодсказкуПоНаименованию()
	
	СписокВыбора = Элементы.Наименование.СписокВыбора; // Массив из Строка
	
	СписокВыбора.Очистить();
	
	Если Объект.ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж Тогда
		СписокВыбора.Добавить(Строка(Объект.КассаККМ));
	Иначе
		СписокВыбора.Добавить(Строка(Объект.Пользователь));
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти
