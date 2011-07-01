-- <queries>
/**
    The "params" attribute is mostly informative for now but can be used in the future
    to pass/add/append parameters for the placeholders in the queries.
*/
-- <query name="write_permissions_sql" params="user_id,user_id"><![CDATA[
  
  (
    (user_id = ? AND permissions LIKE '_rw%')
    OR ( group_id IN (SELECT group_id FROM user_group WHERE user_id= ?) 
      AND permissions LIKE '____rw%')
  )

-- ]]></query>

-- <query name="writable_pages" params="pid,domain_id,id,user_id,user_id"><![CDATA[
  SELECT id as value, alias as label, page_type, pid, permissions FROM pages
     WHERE pid=? AND domain_id=? AND pid !=? AND id>0  AND 
  (
    (user_id = ? AND permissions LIKE '_rw%')
    OR ( group_id IN (SELECT group_id FROM user_group WHERE user_id= ?) 
      AND permissions LIKE '____rw%')
  )
-- ]]></query>

-- </queries>

