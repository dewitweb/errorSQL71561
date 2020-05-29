




/*	==========================================================================================
	15-05-2019:	J.v.Assenbergh
				Make a date from a string
	==========================================================================================
*/
CREATE FUNCTION [sub].[usfCreateDateFromString] 
(
	@DateString nvarChar(50)
)
RETURNS Date
AS
BEGIN

	DECLARE @MonthNameShort nvarchar(MAX)
	DECLARE @PositionMonth int
	DECLARE @MonthNumber varchar(2)
	DECLARE @BeforeMonth varchar(20)
	DECLARE @AfterMonth varchar(20)
	DECLARE @KeepValues as varchar(50)
	DECLARE @Date date

	DECLARE @Day varchar(2)
	DECLARE @Month varchar(2)
	DECLARE @Year varchar(4)

	SET		@KeepValues = '%[^a-z 0-9]%'
	WHILE PatIndex(@KeepValues, @DateString) > 0
		SET @DateString = Stuff(@DateString, PatIndex(@KeepValues, @DateString), 1, ' ')

	WHILE @DateString <> REPLACE(@DateString, '  ', ' ')
		SET @DateString = REPLACE(@DateString, '  ', ' ')

	IF ISNUMERIC(LEFT(LTRIM(@DateString), 1)) = 0 GOTO CreateDateFromString		-- mei 2015 17 werkt niet

	IF	ISNUMERIC(@DateString) = 1 AND LEN(@DateString) = 8
	BEGIN
		SELECT	@BeforeMonth = LEFT(@DateString, 2), 
				@Month = SUBSTRING(@DateString, 3, 2), 
				@AfterMonth = SUBSTRING(@DateString, 5, 4)

		IF ISDATE(@AfterMonth + '-' + @Month + '-' + @BeforeMonth) = 1 GOTO CreateDateFromString
		
		SELECT	@BeforeMonth  = LEFT(@DateString, 4), 
				@Month = SUBSTRING(@DateString, 5, 2), 
				@AfterMonth = SUBSTRING(@DateString, 7, 2)
		
		GOTO CreateDateFromString
	END
	
	IF LEN(@DateString) - LEN(REPLACE(@DateString, ' ', '')) > 1    -- Two spaces in string?
	BEGIN
		SELECT @MonthNameShort = SUBSTRING(@DateString, CHARINDEX(' ', @DateString, 1) + 1, CHARINDEX(' ', @DateString, CHARINDEX(' ', @DateString, 1) + 1) -(CHARINDEX(' ', @DateString, 1) + 1))
		IF	ISNUMERIC(@MonthNameShort) = 1 AND CAST(@MonthNameShort AS int) BETWEEN 1 AND 12
		BEGIN 
			SELECT	@BeforeMonth = LTRIM(RTRIM(LEFT(@DateString, CHARINDEX(' ', @DateString, 1) - 1))),
					@Month = @MonthNameShort,
					@AfterMonth = LTRIM(RTRIM(SUBSTRING(@DateString, CHARINDEX(' ', @DateString, CHARINDEX(' ', @DateString, 1) + 1), LEN(@DateString))))
			GOTO CreateDateFromString
		END
	END

	SELECT	@BeforeMonth = LTRIM(RTRIM(LEFT(@DateString, PositionMonth - 1))),
			@PositionMonth = PositionMonth,
			@MonthNameShort = MonthNameShort,
			@MonthNumber = CAST(MonthNumber AS  varchar(2)),
			@AfterMonth = LTRIM(RTRIM(SUBSTRING(@DateString, ((PositionMonth) + LEN(MonthNameShort)), LEN(@DateString))))
	FROM
			(
				SELECT	CHARINDEX(MonthNameShort, @DateString, 2) PositionMonth,
						MonthNameShort,
						MonthNumber
						--LEN(MonthNameShort)
				FROM	[ait].[viewMonthNameShortByLanguage]
				WHERE	CHARINDEX(MonthNameShort, @DateString, 1) > 0
				AND		ISNUMERIC(MonthNameShort) = 0
				--AND		[langid] = 7
			) mnbl

	SET @Month = @MonthNumber

CreateDateFromString:
	IF	LEN(@BeforeMonth) = 4
	BEGIN
		SET	@Year = @BeforeMonth
		SET	@Day = @AfterMonth	
	END

	IF	LEN(@AfterMonth) = 4
	BEGIN
		SET	@Year = @AfterMonth
		SET	@Day = @BeforeMonth
	END

	IF ISDATE(@Year + '-' + @Month + '-' + @Day) = 1
	BEGIN
		SET @Date = @Year + '-' + @Month + '-' + @Day
	END

	RETURN	@Date

END
/*	== sub.usfCreateDateFromString ===========================================================	*/
