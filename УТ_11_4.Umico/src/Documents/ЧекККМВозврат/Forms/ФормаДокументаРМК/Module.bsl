
#Область СлужебныеПроцедурыИФункции

&ИзменениеИКонтроль("ИнформацияОбОплате")
&НаКлиентеНаСервереБезКонтекста
//@skip-check extension-variable-prefix
Функция UMC_ИнформацияОбОплате(Форма)

	ОплатаПлатежнымиКартамиОтменено = 0;
	Для Каждого СтрокаТЧ Из Форма.Объект.ОплатаПлатежнымиКартами Цикл
		Если СтрокаТЧ.ОплатаОтменена Тогда
			ОплатаПлатежнымиКартамиОтменено = ОплатаПлатежнымиКартамиОтменено + СтрокаТЧ.Сумма;
		КонецЕсли;
	КонецЦикла;

	Форма.СуммаДокумента = ЦенообразованиеКлиентСервер.ПолучитьСуммуДокумента(Форма.Объект.Товары, Форма.Объект.ЦенаВключаетНДС);

	Если Форма.Объект.ЦенаВключаетНДС Тогда
		СуммаБезСкидки = Форма.СуммаДокумента;
	Иначе
		СуммаБезСкидки = Форма.СуммаДокумента - Форма.Объект.Товары.Итог("СуммаНДС");
	КонецЕсли;

	ИнформацияОбОплате = Новый Структура;
	ИнформацияОбОплате.Вставить("Документ",               Форма.Объект.Ссылка);

	ИнформацияОбОплате.Вставить("Наличные",               Форма.Объект.ВыданоНаличными);
	ИнформацияОбОплате.Вставить("ПлатежныеКарты",         Форма.Объект.ОплатаПлатежнымиКартами.Итог("Сумма"));
	ИнформацияОбОплате.Вставить("ПлатежныеКартыОтменено", ОплатаПлатежнымиКартамиОтменено);
	ИнформацияОбОплате.Вставить("ПодарочныеСертификаты",  0);
	ИнформацияОбОплате.Вставить("БонусныеБаллы",          0);

	ИнформацияОбОплате.Вставить("СуммаДокумента",        Форма.СуммаДокумента);
	ИнформацияОбОплате.Вставить("СуммаКОплате",          СуммаБезСкидки);
	ИнформацияОбОплате.Вставить("СуммаСкидки",           0);
	ИнформацияОбОплате.Вставить("ИтогоОплачено",         ИнформацияОбОплате.Наличные + ОплатаПлатежнымиКартамиОтменено);

	ИнформацияОбОплате.Вставить("ДоступныеВидыОплаты", ДоступныеВидыОплаты(Форма));

	#Вставка
	ИнформацияОбОплате
	.Вставить("БаллыUmico", Форма.Объект.UMC_ОплаченноБалламиUmico);
	ИнформацияОбОплате.Вставить("ИтогоОплачено", ИнформацияОбОплате.Наличные + ОплатаПлатежнымиКартамиОтменено
		+ ИнформацияОбОплате.БаллыUmico);
	ИнформацияОбОплате.Вставить("СуммаКОплате", СуммаБезСкидки - ИнформацияОбОплате.БаллыUmico);
	
	Форма.ИнформационнаяПанельСуммаКВозвратуUmico = ИнформацияОбОплате.БаллыUmico;
	#КонецВставки

	Возврат ИнформацияОбОплате;

КонецФункции

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
		Объект.UMC_НомерСчетаUmico) Тогда

		UMC_ЗапуститьПередачуИнформацииОЧекеВUmico();	

	КонецЕсли;

КонецПроцедуры

&НаКлиенте
Процедура UMC_ЗапуститьПередачуИнформацииОЧекеВUmico()
	
	UMC_СтруктураОтвета = UMC_ПередатьИнформациюОЧекеВUmico();
	Если Не UMC_СтруктураОтвета.Результат Тогда
		UMC_ТекстСообщения = НСтр("ru = 'Не удалось передать сведения о документе в Umico. Повторить попытку?'");
		ПоказатьВопрос(Новый ОписаниеОповещения("UMC_ПробитьЧекОшибкаЗавершение", ЭтотОбъект), UMC_ТекстСообщения,
			РежимДиалогаВопрос.ДаНет, 10);
	КонецЕсли;
	
КонецПроцедуры

// Передает информацию о чеке в Umico.
// 
// Возвращаемое значение:
//  Структура - UMC передать информацию о чеке в Umico:
// * Результат - Булево -
&НаСервере
Функция UMC_ПередатьИнформациюОЧекеВUmico()

	UMC_ОбработкаОбменаСUmico = Обработки.UMC_ОбменСUmico.Создать();
	UMC_ОбработкаОбменаСUmico.КассаККМ = Объект.КассаККМ;
	UMC_ОбработкаОбменаСUmico.ВариантИспользования = Перечисления.UMC_ВариантыИспользованияПодключенияКUmico.ДляРозничныхПродаж;

	Если UMC_ОбработкаОбменаСUmico.ОпределитьПараметрыПодключения() Тогда

		Возврат UMC_ОбработкаОбменаСUmico.ЗарегистрироватьЧек(Объект.Ссылка);

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