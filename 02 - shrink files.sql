SET NOCOUNT ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET STATISTICS IO, TIME OFF

IF OBJECT_ID('tempdb.dbo.#database_files') IS NOT NULL
    DROP TABLE #database_files

CREATE TABLE #database_files (
      [db_name]      SYSNAME
    , [name]         SYSNAME
    , [type]         SYSNAME
    , [size_mb]      BIGINT
    , [used_size_mb] BIGINT
)

DECLARE @sql NVARCHAR(MAX) = STUFF((
    SELECT '
USE ' + QUOTENAME([name]) + '
INSERT INTO #database_files
SELECT DB_NAME()
     , [name]
     , [type_desc]
     , [size] * 8 / 1024
     , FILEPROPERTY([name], ''SpaceUsed'') * 8 / 1024
FROM sys.database_files WITH(NOLOCK);'
    FROM sys.databases WITH(NOLOCK)
    WHERE [state] = 0
        AND ISNULL(HAS_DBACCESS([name]), 0) = 1
    FOR XML PATH(''), TYPE).value('(./text())[1]', 'NVARCHAR(MAX)'), 1, 2, '')

EXEC sys.sp_executesql @sql

SELECT [db_name]
     , [name]
     , [type]
     , [size_mb]
     , [used_size_mb]
     , [shrink_size_mb] = [size_mb] - [used_size_mb]
     , 'USE ' + QUOTENAME([db_name]) 
            + CASE WHEN [db_name] = 'tempdb' AND [type] = 'ROWS'
                  THEN '; DBCC FREEPROCCACHE; CHECKPOINT;'
                  ELSE ';'
              END + ' DBCC SHRINKFILE (N''' + [name] + ''' , ' + CAST([size_mb] AS NVARCHAR(MAX)) + ')'
FROM #database_files
ORDER BY [shrink_size_mb] DESC
