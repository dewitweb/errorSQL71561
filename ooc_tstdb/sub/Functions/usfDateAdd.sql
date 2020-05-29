

/*	==========================================================================================
	24-07-2018:	J.v.Assenbergh
				Clean-up a string for searching
	==========================================================================================
*/
CREATE FUNCTION [sub].[usfDateAdd] 
(
	@Interval nvarChar(12),
	@Increment smallint,
	@Date datetime2
)
RETURNS datetime2
AS
BEGIN

DECLARE @Return datetime

SELECT @Return = 
		CASE @interval
			WHEN 'year' 
				THEN DATEADD(year, @Increment, @Date)
			WHEN 'quarter' 
				THEN DATEADD(quarter, @Increment, @Date)
			WHEN 'month' 
				THEN DATEADD(month, @Increment, @Date)
			WHEN 'dayofyear' 
				THEN DATEADD(dayofyear, @Increment, @Date)
			WHEN 'day' 
				THEN DATEADD(day, @Increment, @Date)
			WHEN 'week' 
				THEN DATEADD(week, @Increment, @Date)
			WHEN 'weekday' 
				THEN DATEADD(weekday, @Increment, @Date)
			WHEN 'hour' 
				THEN DATEADD(hour, @Increment, @Date)
			WHEN 'minute' 
				THEN DATEADD(minute, @Increment, @Date)
			WHEN 'second' 
				THEN DATEADD(second, @Increment, @Date)
			WHEN 'millisecond' 
				THEN DATEADD(millisecond, @Increment, @Date)
			WHEN 'microsecond' 
				THEN DATEADD(microsecond, @Increment, @Date)
			WHEN 'nanosecond' 
				THEN DATEADD(nanosecond, @Increment, @Date)

		END

	RETURN	@Return

END


