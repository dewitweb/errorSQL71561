


CREATE VIEW [sub].[viewApplicationSetting_NewsItemPage]
AS

SELECT	PermissionID	PageID,
		PermissionCode	PageCode,
		CASE	WHEN PermissionCode = 'ui-declarant-dashboard' THEN 'Dashboard werkgevers'
				WHEN PermissionCode = 'ui-regelingen-uitleg' THEN 'Regelingenuitleg'
				WHEN PermissionCode = 'ui-declarant-insert' THEN 'Declaratie indienen'
		END				PageDescription
FROM	auth.tblPermission
WHERE	ApplicationID = 1
AND		PermissionCode IN
		(
			'ui-declarant-dashboard',
			'ui-regelingen-uitleg',
			'ui-declarant-insert'
		)
