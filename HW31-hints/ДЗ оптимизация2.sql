﻿	/*
	1. Чтобы оптимизировать необходимо хорошо знать структуру данных, или знать того, кто знает ее) +
	2. Формитирование текста запроса, улучшение читабельности +
	2. убрать лишние таблицы, которые не используются ни в выводе , ни в условии +
	3. Заменить подзапросы на join или cte, или на процедуры -
	4. использовать временные таблицы + заменила cte на временную таблицу
	4. Заворачмваем запрос в процедурую Когда SQL Server выполняет процедуры, значения всех используемых при компиляции параметров включаются в формируемый план запроса.
	Если эти значения типичны для последующих вызовов процедуры, то компиляция и выполнение хранимой процедуры с этим планом запроса происходит быстрее.
	5. добавить индексы, либо разобраться , почему  имеющиеся индексы не используются. Можно использовать для этого хинты 
	*/
Select ord.CustomerID
	,  det.StockItemID
	,  SUM(det.UnitPrice) --заменить на окно
	,  SUM(det.Quantity)  --заменить на окно
	,  COUNT(ord.OrderID) --заменить на окно
	FROM Sales.Orders AS ord
	INNER JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
	INNER JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
	INNER JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID -- не используетя
	INNER JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID -- не используется, не корректно соединять по StockItemID, по одному товару может быть тысячи транзакций, это искажает данные на выходе
	
WHERE Inv.BillToCustomerID != ord.CustomerID -- покупатель в заказе отличается от покупателя в счете
	AND (Select SupplierId
			FROM Warehouse.StockItems AS It
			Where It.StockItemID = det.StockItemID) = 12 -- выбираем товары определенного поставщика
	AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
			FROM Sales.OrderLines AS Total
			Join Sales.Orders AS ordTotal
			On ordTotal.OrderID = Total.OrderID
			WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000 --сумма всех заказов по клиенту больше определенной суммы можно вынести в CTE по клиентам
	AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0 -- счет выставлен в день заказа, т.е. дата заказа  = дате счетаб если убрать вычисление, можно использовать индексы на даты
GROUP BY ord.CustomerID, det.StockItemID --?
ORDER BY ord.CustomerID, det.StockItemID;
/*
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 0 мс, истекшее время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 125 мс, истекшее время = 134 мс.

(затронуто строк: 3619)
Таблица "StockItemTransactions". Сканирований 1, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 29, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "StockItemTransactions". Считано сегментов 1, пропущено 0.
Таблица "OrderLines". Сканирований 4, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 331, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "OrderLines". Считано сегментов 2, пропущено 0.
Таблица "CustomerTransactions". Сканирований 5, логических операций чтения 261, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Orders". Сканирований 2, логических операций чтения 883, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Invoices". Сканирований 1, логических операций чтения 11400, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "StockItems". Сканирований 1, логических операций чтения 2, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

 Время работы SQL Server:
   Время ЦП = 750 мс, затраченное время = 980 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 0 мс, истекшее время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.*/

--drop table  #tblCustomerID;

SELECT  ordTotal.CustomerID as CustomerID
into #tblCustomerID
FROM Sales.Orders AS ordTotal
	INNER Join Sales.OrderLines AS Total On ordTotal.OrderID = Total.OrderID
GROUP BY ordTotal.CustomerID
HAVING SUM(Total.UnitPrice*Total.Quantity) > 250000
ORDER BY ordTotal.CustomerID; 

ALTER TABLE #tblCustomerID ADD PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) 
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO
/****** Object:  Index [IX_Sales_Invoices_ConfirmedDeliveryTime]    Script Date: 24.03.2024 9:59:41 ******/
CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_OrderId] ON [Sales].[Invoices]
(
	[OrderId] ASC
)
INCLUDE([InvoiceDate], BillToCustomerID, CustomerID) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [USERDATA]
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Allows quick retrieval of invoices confirmed to have been delivered in a given time period' , @level0type=N'SCHEMA',@level0name=N'Sales', @level1type=N'TABLE',@level1name=N'Invoices', @level2type=N'INDEX',@level2name=N'IX_Sales_Invoices_OrderId'
GO
/****** Object:  Index [FK_Sales_Orders_CustomerID]    Script Date: 24.03.2024 10:04:57 ******/
CREATE NONCLUSTERED INDEX [IX_Sales_Orders_CustomerID] ON [Sales].[Orders]
(
	[CustomerID] ASC
)
INCLUDE([OrderDate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [USERDATA]
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Auto-created to support a foreign key' , @level0type=N'SCHEMA',@level0name=N'Sales', @level1type=N'TABLE',@level1name=N'Orders', @level2type=N'INDEX',@level2name=N'IX_Sales_Orders_CustomerID'
GO 

Select  ord.CustomerID
	,  det.StockItemID
	,  SUM(det.UnitPrice) 
	,  SUM(det.Quantity)  
	,  COUNT(ord.OrderID) 
	FROM 
		  #tblCustomerID AS  CustCTE
		 INNER JOIN Sales.Orders AS ord ON ord.CustomerID = CustCTE.CustomerID 
		 INNER JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
		 INNER JOIN Sales.Invoices AS Inv  ON Inv.OrderID = ord.OrderID AND Inv.InvoiceDate = ord.OrderDate AND Inv.BillToCustomerID != ord.CustomerID AND Inv.CustomerID = ord.CustomerID
		 INNER JOIN Warehouse.StockItems AS It ON It.StockItemID = det.StockItemID AND It.SupplierId = 12

GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;

/*
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 0 мс, истекшее время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 32 мс, истекшее время = 46 мс.

(затронуто строк: 3619)
Таблица "OrderLines". Сканирований 2, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 355, физических операций чтения LOB 5, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 795, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "OrderLines". Считано сегментов 1, пропущено 0.
Таблица "Orders". Сканирований 1, логических операций чтения 158, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Invoices". Сканирований 1, логических операций чтения 223, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "StockItems". Сканирований 1, логических операций чтения 2, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "#tblCustomerID______________________________________________________________________________________________________000000000013". Сканирований 1, логических операций чтения 2, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

(затронута одна строка)

 Время работы SQL Server:
   Время ЦП = 62 мс, затраченное время = 354 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 0 мс, истекшее время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.
*/

set statistics io, time on
DBCC FREEPROCCACHE;
GO
exec [dbo].[usp_ShowCache]
Go
