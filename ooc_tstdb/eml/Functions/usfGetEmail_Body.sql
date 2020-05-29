

CREATE FUNCTION [eml].[usfGetEmail_Body]
/*	==============================================================
	Purpose:	Get EmailBody

	14-01-2020	Jaap van Assenbergh
	==============================================================	*/
(
	@TemplateID		int
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @EmailBody varchar(MAX)

	SELECT	@EmailBody = '<html>'
				+ '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style>'
                + '<p>' + BodyHeader + '</p>'
                + '<p>' + BodyMessage + '</p>'
                + '<br>' 
                + '<p>' + BodyFooter + '</p>'
				+ '<html>'
	FROM	eml.tblEmailTemplate
	WHERE	TemplateID = @TemplateID

	RETURN @EmailBody
END

/*	==	eml.usfGetEmailBody ======================================	*/
