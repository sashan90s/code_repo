-- In the test:
EXEC sp_set_session_context @key = 'CurrencyFilter', @value = 'USD';

-- In the view:
SELECT amount, customerId, employeeId, itemId, date
FROM FinancialApp.Sales
JOIN FinancialApp.CurrencyConversion
  ON Sales.currency = CurrencyConversion.SourceCurrency
WHERE CurrencyConversion.DestCurrency = SESSION_CONTEXT(N'CurrencyFilter');
