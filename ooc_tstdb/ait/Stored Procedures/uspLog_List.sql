
CREATE PROCEDURE [ait].[uspLog_List]
@SearchString varchar(MAX),
@SortBy				varchar(50)	= 'LogDateTime',
@SortDescending		bit	= 1,
@PageNumber			int,
@RowspPage			int
--@Top int = 0
AS
/*	==========================================================================================
	Purpose: 	Get list from ait.tblLog.

	02-12-2019	Jaap van Assenbergh	OTIBSUB-1703 Errorlog-pagina gaan pagen
	20-06-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

SET @SearchString = ISNULL(@SearchString, '')

SELECT @SearchString = sub.usfCreateSearchString (@SearchString)
DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

SET @SortBy = ISNULL(@SortBy, 'LogDateTime')
SET @SortDescending = ISNULL(@SortDescending, 1)

SELECT
		LogID,
		LogDateTime,
		LogMessage,
		LogLevel,
		LogURL,
		PostBody,
		Stacktrace,
		CurrentUserID
FROM	(
			SELECT
					LogID,
					LogDateTime,
					LogMessage,
					LogLevel,
					LogURL,
					PostBody,
					Stacktrace,
					CurrentUserID,
					CASE WHEN @SortDescending = 0 
						THEN CAST(SortBy AS varchar(max)) 
						ELSE NULL 
					END	AS SortByAsc,
					CASE WHEN @SortDescending = 1 
						THEN CAST(SortBy AS varchar(max)) 
						ELSE NULL 
					END	AS SortByDesc
			FROM	(
						SELECT
								LogID,
								LogDateTime,
								LogMessage,
								LogLevel,
								LogURL,
								PostBody,
								Stacktrace,
								CurrentUserID,
								CASE 
									WHEN @SortBy = 'LogDateTime'	THEN CONVERT(varchar(19), LogDateTime, 112)
								ELSE CONVERT(varchar(19), LogDateTime, 112)
								END SortBy
						FROM	ait.tblLog
						CROSS JOIN @SearchWord
						WHERE	'T' =	CASE 
											WHEN @SearchString = '' 
												THEN 'T'	
											WHEN CHARINDEX(Word, LogMessage, 1) > 0 
												THEN 'T'
											WHEN CHARINDEX(Word, LogURL, 1) > 0 
												THEN 'T'
											WHEN CHARINDEX(Word, PostBody, 1) > 0 
												THEN 'T'
											WHEN CHARINDEX(Word, Stacktrace, 1) > 0 
												THEN 'T'
										END 
					) Search
		) OrderBy
		ORDER BY	
                ROW_NUMBER() OVER (ORDER BY SortByAsc ASC, SortByDesc DESC)
		OFFSET ((@PageNumber - 1) * @RowspPage) ROWS
		FETCH NEXT @RowspPage ROWS ONLY;

/*	== ait.uspLog_List =======================================================================	*/
