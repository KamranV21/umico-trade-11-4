// @strict-types
#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ОбработчикиСобытий

&После("ОбработкаЗаполнения")
Процедура UMC_ОбработкаЗаполнения(ДанныеЗаполнения, СтандартнаяОбработка)
	
	Если НЕ ТипЗнч(ДанныеЗаполнения) = Тип("Структура") Тогда
		Возврат;
	КонецЕсли;
	
	UMC_СтруктураЗаполнения = ДанныеЗаполнения; // см. UMC_ОбменСUmico.НоваяСтруктураЗаполненияСписания
	
	UMC_СписаниеЗаСчетUmico = Ложь;
	
	UMC_СтруктураЗаполнения.Свойство("СписаниеЗаСчетUmico", UMC_СписаниеЗаСчетUmico);
	
	Если UMC_СписаниеЗаСчетUmico = Ложь Тогда
		Возврат;	
	КонецЕсли;
	
	UMC_Основание = UMC_СтруктураЗаполнения.Основание;
	
	UMC_Реквизиты = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(UMC_Основание, "Организация, Контрагент, Партнер, UMC_ОплаченноБалламиUmico");
	
	Организация = UMC_Реквизиты.Организация;
	Контрагент = UMC_Реквизиты.Контрагент;
	
	Если ТипЗнч(UMC_Основание) = Тип("ДокументСсылка.РеализацияТоваровУслуг") Тогда
		ХозяйственнаяОперация = Перечисления.ХозяйственныеОперации.СписаниеДебиторскойЗадолженности;
	ИначеЕсли ТипЗнч(UMC_Основание) = Тип("ДокументСсылка.РеализацияТоваровУслуг") Тогда
		ХозяйственнаяОперация = Перечисления.ХозяйственныеОперации.СписаниеКредиторскойЗадолженности;
	КонецЕсли;
	
	UMC_Выборка = UMC_ПолучитьСведенияОРасчетахСКлиентамиПоОснованию(UMC_Основание);
	Если UMC_Выборка.Следующий() Тогда
		UMC_НоваяСтрока = Задолженность.Добавить();	
		UMC_НоваяСтрока.ТипРасчетов = Перечисления.ТипыРасчетовСПартнерами.РасчетыСКлиентом;
		UMC_НоваяСтрока.Партнер = UMC_Реквизиты.Партнер;
		UMC_НоваяСтрока.Заказ = UMC_Выборка.ЗаказКлиента;
		UMC_НоваяСтрока.ВалютаВзаиморасчетов = UMC_Выборка.Валюта;
		UMC_НоваяСтрока.Сумма = UMC_Реквизиты.UMC_ОплаченноБалламиUmico;
		UMC_НоваяСтрока.ИдентификаторСтроки = Строка(Новый УникальныйИдентификатор);
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Получить сведения о расчетах с клиентами по основанию.
// 
// Параметры:
//  UMC_Основание - ДокументСсылка.РеализацияТоваровУслуг - UMC основание
// 
// Возвращаемое значение:
//  ВыборкаИзРезультатаЗапроса:
//	* ЗаказКлиента - ОпределяемыйТип.ОбъектРасчетов
//	* Валюта - СправочникСсылка.Валюты
Функция UMC_ПолучитьСведенияОРасчетахСКлиентамиПоОснованию(UMC_Основание)

	UMC_Запрос = Новый Запрос("ВЫБРАТЬ ПЕРВЫЕ 1
						  |	РасчетыСКлиентами.ЗаказКлиента,
						  |	РасчетыСКлиентами.Валюта
						  |ИЗ
						  |	РегистрНакопления.РасчетыСКлиентами КАК РасчетыСКлиентами
						  |ГДЕ
						  |	РасчетыСКлиентами.Регистратор = &Регистратор");
	UMC_Запрос.УстановитьПараметр("Регистратор", UMC_Основание);

	Возврат UMC_Запрос.Выполнить().Выбрать();

КонецФункции

#КонецОбласти

#КонецЕсли