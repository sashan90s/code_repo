--nesting example
DECLARE @Var1 INT = 9
IF @Var1 % 5 = 0 BEGIN
	IF @Var1 % 3 = 0 BEGIN 
		print 'the number is divisible by 3 and 5'
	END
	ELSE BEGIN 
		print 'the number is divisible by 5'
	END
END
ELSE BEGIN 
	IF @Var1 % 3 = 0 BEGIN 
		print 'the number is divisible by 3'
	END
	ELSE BEGIN 
		print 'the number is not divisible by 3 or 5'
	END
END

