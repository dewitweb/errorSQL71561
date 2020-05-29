
CREATE PROCEDURE [ait].[uspWriteStringToFile] (
@String		varchar(max),
@Path		varchar(255),
@Filename	varchar(100)
)
AS
/*	==========================================================================================
	Purpose:	Write a text file to filestorage.

	26-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE	@objFileSystem		int,
        @objTextStream		int,
		@objErrorObject		int,
		@strErrorMessage	varchar(1000),
	    @Command			varchar(1000),
	    @hr					int,
		@fileAndPath		varchar(355),
		@xml				xml

SET NOCOUNT ON

/*	Set FileAndPath.	*/
SET @FileAndPath = @path + '\' + @filename

/*	Make sure the Ole Automation Procedures and xm_cmdshell options are accessable.	*/
EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'Ole Automation Procedures', 1
RECONFIGURE;
EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE

/*	Start process.	*/
SELECT @strErrorMessage = 'Opening the File System Object'

EXEC @hr = sp_OACreate 'Scripting.FileSystemObject', @objFileSystem OUT

IF @HR = 0 
	SELECT @objErrorObject = @objFileSystem, @strErrorMessage = 'Creating file "' + @FileAndPath + '"'

IF @HR = 0 
	EXEC @hr = sp_OAMethod @objFileSystem, 'CreateTextFile', @objTextStream OUT, @FileAndPath, 2, False
	
IF @HR = 0 
	SELECT @objErrorObject = @objTextStream, @strErrorMessage = 'Writing to the file "' + @FileAndPath + '"'

IF @HR = 0 
	EXEC @hr = sp_OAMethod @objTextStream, 'Write', NULL, @String

IF @HR = 0 
	SELECT @objErrorObject = @objTextStream, @strErrorMessage = 'Closing the file "' + @FileAndPath + '"'

IF @HR = 0 
	EXEC @hr = sp_OAMethod @objTextStream, 'Close'

/*	If an error occurred, show the error.	*/
IF @HR <> 0
BEGIN
	DECLARE 
		@Source			varchar(255),
		@Description	varchar(255),
		@Helpfile		varchar(255),
		@HelpID			int
	
	EXECUTE sp_OAGetErrorInfo @objErrorObject, @source OUTPUT, @Description output, @Helpfile output, @HelpID output
	
	SELECT @strErrorMessage = 'Error whilst '
			+ COALESCE(@strErrorMessage, 'doing something')
			+ ', ' + COALESCE(@Description, '')

	RAISERROR (@strErrorMessage,16,1)
END

/*	Clean up stream.	*/
EXEC sp_OADestroy @objTextStream

/*	Disable the Ole Automation Procedures and xm_cmdshell options.	*/
EXEC master.dbo.sp_configure 'xp_cmdshell', 0
RECONFIGURE
EXEC sp_configure 'Ole Automation Procedures', 0
RECONFIGURE;
EXEC master.dbo.sp_configure 'show advanced options', 0
RECONFIGURE

RETURN

/*	== ait.uspWriteStringToFile ==============================================================	*/
