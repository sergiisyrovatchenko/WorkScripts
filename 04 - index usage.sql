SELECT
	  index_name = i.name
	, [index_columns] = STUFF((
		SELECT ', ' + COL_NAME(ic.[object_id], ic.column_id) + IIF(ic.is_descending_key = 1, ' (DESC)', '')
		FROM sys.index_columns ic
		WHERE ic.[object_id] = i.[object_id]
			AND ic.index_id = i.index_id
			AND ic.is_included_column = 0
		FOR XML PATH('')), 1, 2, '')
	, included_columns = STUFF((
		SELECT ', ' + COL_NAME(ic.[object_id], ic.column_id)
		FROM sys.index_columns ic
		WHERE ic.[object_id] = i.[object_id]
			AND ic.index_id = i.index_id
			AND ic.is_included_column = 1
		FOR XML PATH('')), 1, 2, '') 
	, i.type_desc
	, i.is_unique
	, i.is_primary_key
	, i.fill_factor
	, i.is_hypothetical
	, i.is_disabled
	, i.has_filter
	, us.user_seeks
	, us.user_scans
	, us.user_lookups
	, us.user_updates
	, us.last_action
FROM sys.indexes i
JOIN sys.objects o ON i.[object_id] = o.[object_id]
LEFT JOIN (
	SELECT *, last_action = (
				SELECT MAX(last_action)
				FROM (VALUES (last_user_seek), (last_user_scan), (last_user_lookup), (last_user_update)) t(last_action)
			)
	FROM sys.dm_db_index_usage_stats
	WHERE database_id = DB_ID()
) us ON us.index_id = i.index_id AND i.[object_id] = us.[object_id]
WHERE o.[type] IN ('U', 'V')
	AND o.is_ms_shipped = 0
	AND i.[object_id] = OBJECT_ID('t1')


