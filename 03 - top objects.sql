SET NOCOUNT ON
SET STATISTICS IO, TIME OFF

IF OBJECT_ID('tempdb.dbo.#object_size') IS NOT NULL
    DROP TABLE #object_size

CREATE TABLE #object_size (
      [object_id]     INT PRIMARY KEY
    , [total_size_mb] DECIMAL(32,2)
    , [used_size_mb]  DECIMAL(32,2)
    , [rows]          BIGINT
)

INSERT INTO #object_size
SELECT i.[object_id]
     , SUM(a.[total_pages])
     , SUM(a.[used_pages])
     , SUM(CASE WHEN i.[index_id] IN (0, 1) AND a.[type] = 1 THEN p.[rows] END)
FROM sys.indexes i WITH(NOLOCK)
JOIN sys.partitions p WITH(NOLOCK) ON i.[object_id] = p.[object_id] AND i.[index_id] = p.[index_id]
JOIN sys.allocation_units a WITH(NOLOCK) ON p.[partition_id] = a.[container_id]
WHERE i.[is_disabled] = 0
    AND i.[is_hypothetical] = 0
    AND a.[total_pages] > 0
GROUP BY i.[object_id]

SELECT TOP(100) o.[object_id]
               , s.name + '.' + o.name
               , o.[type]
               , i.rows
               , total_space = CAST(i.[total_size_mb] * 8. / 1024 AS DECIMAL(18, 2))
               , used_space = CAST(i.[used_size_mb] * 8. / 1024 AS DECIMAL(18, 2))
               , unused_space = CAST((i.[total_size_mb] - i.[used_size_mb]) * 8. / 1024 AS DECIMAL(18, 2))
FROM sys.objects o WITH(NOLOCK)
JOIN sys.schemas s WITH(NOLOCK) ON o.[schema_id] = s.[schema_id]
JOIN #object_size i ON o.[object_id] = i.[object_id]
WHERE o.[type] IN ('V', 'U')
    AND o.is_ms_shipped = 0
ORDER BY i.[total_size_mb] DESC

