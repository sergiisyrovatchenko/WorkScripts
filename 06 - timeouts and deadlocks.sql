SELECT CAST('<?query --' + CHAR(13) + t.query_sql_text + CHAR(13) + '--?>' AS XML)
     , OBJECT_NAME(q.[object_id])
     , i.start_time
     , s.execution_type_desc
     , s.count_executions
     , s.avg_duration / 1000
     , s.min_duration / 1000
     , s.[max_duration] / 1000
FROM sys.query_store_runtime_stats_interval i
JOIN sys.query_store_runtime_stats s ON i.runtime_stats_interval_id = s.runtime_stats_interval_id
JOIN sys.query_store_plan p ON s.plan_id = p.plan_id
JOIN sys.query_store_query q ON p.query_id = q.query_id
JOIN sys.query_store_query_text t ON q.query_text_id = t.query_text_id
WHERE i.start_time >= '20201015'
    AND s.execution_type IN (3,4)
    --AND t.query_sql_text LIKE '%SalesOrder%'
