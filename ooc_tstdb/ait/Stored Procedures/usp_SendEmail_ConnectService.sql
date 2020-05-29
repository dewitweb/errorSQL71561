
CREATE PROCEDURE [ait].[usp_SendEmail_ConnectService]
AS
/*	==========================================================================================
	Purpose:	Send an e-mail to support@ambitionit.nl if a sync-run is failed.

	Notes:

	12-03-2019: Jaap van Assenbergh Initial version.
	==========================================================================================	*/

DECLARE @LastConnectDate Date

SELECT	@LastConnectDate = MIN(DeclarationDate)
FROM	sub.tblDeclaration decl
INNER JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = decl.DeclarationID
WHERE   dus.SentToSourceSystemDate IS NULL
AND		decl.DeclarationDate < CAST(GETDATE() AS date)
AND		decl.StartDate <= CAST(GETDATE() AS date)
AND		decl.DeclarationID >= 400000
AND		decl.DeclarationStatus = '0022'
AND		dus.DeclarationAcceptedDate IS NOT NULL

SELECT  @LastConnectDate

IF @LastConnectDate IS NOT NULL
BEGIN
    DECLARE @EmailHeaders	xml = N'<headers>'
                                    + '<header key="subject" value="Connectservice mogelijk uitgevallen" />'
                                    + '<header key="to" value="support@ambitionit.nl" />'
                                + '</headers>'

    DECLARE @EmailBody nvarchar(max) = 'Connect service heeft niets meer verstuurd sinds ' 
                                        + CONVERT(varchar(20), @LastConnectDate, 105)

    INSERT INTO eml.tblEmail (EmailHeaders, EmailBody) VALUES (@EmailHeaders, @EmailBody)
END

RETURN
/*	== ait.usp_SendEmail_ConnectService ======================================================	*/
