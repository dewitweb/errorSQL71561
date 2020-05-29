
CREATE FUNCTION [eml].[usfGetEmail_Header]
/*	==============================================================
	Purpose:	Get Email Header

	14-01-2020	Jaap van Assenbergh
	==============================================================	*/
(
	@TemplateID		int
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @EmailBody varchar(MAX)

	SELECT	@EmailBody = '<headers>'
                + '<header key="subject" value="' + TemplateSubject + '<%SubjectAddition%>" />'
                + '<header key="to" value="<%Recipients%>" />'
                + '</headers>'
	FROM	eml.tblEmailTemplate
	WHERE	TemplateID = @TemplateID

	RETURN @EmailBody
END

/*	==	eml.usfGetEmailBody ======================================	*/
