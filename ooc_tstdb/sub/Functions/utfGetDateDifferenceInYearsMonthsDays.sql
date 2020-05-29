CREATE FUNCTION [sub].[utfGetDateDifferenceInYearsMonthsDays]
(
    @FromDate	datetime, 
	@ToDate		datetime
)
RETURNS @tblDateDifference TABLE 
(
	DifferenceInYears	smallint,  
	DifferenceInMonths	smallint, 
	DifferenceInDays	smallint
)
AS
BEGIN
    DECLARE @Years			smallint, 
			@Months			smallint, 
			@Days			smallint, 
			@tmpFromDate	datetime

	SET @ToDate = DATEADD(DAY, -1, @ToDate)

    SET @Years = DATEDIFF(YEAR, @FromDate, @ToDate)
				 - (CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @FromDate, @ToDate), @FromDate) > @ToDate 
						THEN 1 
						ELSE 0 
					END
				  ) 
    
    SET @tmpFromDate = DATEADD(YEAR, @Years, @FromDate)

    SET @Months = DATEDIFF(MONTH, @tmpFromDate, @ToDate)
				  - (CASE WHEN DATEADD(MONTH,DATEDIFF(MONTH, @tmpFromDate, @ToDate), @tmpFromDate) > @ToDate 
						THEN 1 
						ELSE 0 
					 END
					) 
    
    SET @tmpFromDate = DATEADD(MONTH, @Months, @tmpFromDate)

    SET @Days = DATEDIFF(DAY, @tmpFromDate, @ToDate)
				- (CASE WHEN DATEADD(DAY, DATEDIFF(DAY, @tmpFromDate, @ToDate), @tmpFromDate) > @ToDate 
					THEN 1 
					ELSE 0 
				   END
				  ) 
    
	-- Correct variables (less then zero is overlap and the difference is set to zero).
	IF @Years < 0 OR @Months < 0 OR @Days < 0
	BEGIN
		SELECT	@Years = 0,
				@Months = 0,
				@Days = 0
	END

    INSERT INTO @tblDateDifference
    VALUES (@Years, @Months, @Days)
    
    RETURN
END
