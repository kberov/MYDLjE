-- <queries>
/**
    The "params" attribute is mostly informative for now but can be used in the future
    to pass/add/append parameters for the placeholders in the queries.
*/
-- <query name="write_permissions_sql" params="user_id,user_id,user_id"><![CDATA[
  (
    (user_id = ? AND permissions LIKE '_rw%')
    OR ( group_id IN (SELECT group_id FROM user_group WHERE user_id= ?) 
      AND permissions LIKE '____rw____')
    OR permissions LIKE '_______rw_'
    OR EXISTS 
        (SELECT ug.group_id FROM user_group ug WHERE ug.user_id= ? and ug.group_id=1)
  )

-- ]]></query>
-- <query name="read_permissions_sql" params="user_id,user_id"><![CDATA[
  (
    (user_id = ? AND permissions LIKE '_r%')
    OR ( group_id IN (SELECT group_id FROM user_group WHERE user_id= ?) 
      AND permissions LIKE '____r_____')
    OR permissions LIKE '_______r__'
    OR EXISTS 
        (SELECT ug.group_id FROM user_group ug WHERE ug.user_id= ? and ug.group_id=1)
  )
-- ]]></query>
-- <query name="writable_pages_select_menu" params="pid,domain_id,id,user_id,user_id,user_id"><![CDATA[
  SELECT id as value, alias as label, page_type, pid, permissions FROM pages
     WHERE pid=? AND domain_id=? AND pid !=? AND id>0  AND 
  (
    (user_id = ? AND permissions LIKE '_rw%')
    OR ( group_id IN (SELECT group_id FROM user_group WHERE user_id= ?) 
      AND permissions LIKE '____rw____')
    OR permissions LIKE '_______rw_'
    OR EXISTS 
        (SELECT ug.group_id FROM user_group ug WHERE ug.user_id= ? and ug.group_id=1)
  )
-- ]]></query>
-- <query name="delete_domain_content" params="domain_id"><![CDATA[
  DELETE FROM content WHERE page_id IN 
  (SELECT id FROM pages WHERE domain_id=?)
-- ]]></query>

-- <query name="readable_pages" params="pid,domain_id,id,user_id,user_id,user_id"><![CDATA[
  SELECT * FROM pages p
     WHERE p.pid=? AND p.domain_id=? AND p.pid !=? AND id>0  AND 
  (
    (p.user_id = ? AND p.permissions LIKE '_r%')
    OR ( p.group_id IN (SELECT ug.group_id FROM user_group ug WHERE ug.user_id= ?) 
         AND p.permissions LIKE '____r_____'
    )
    OR p.permissions LIKE '_______r__'
    OR EXISTS 
        (SELECT ug.group_id FROM user_group ug WHERE ug.user_id= ? and ug.group_id=1)
  )
-- ]]></query>

--TODO: Think how to not always pass current user_id
-- May be by using stored functions like the one below
-- or by replacing/interpolating the safe otherwise parameters right into the query.
-- <query name="msession_user_id" params=""><![CDATA[
  DELIMITER //
  CREATE FUNCTION `msession_user_id`() 
  RETURNS INT(11)
  BEGIN
  DECLARE c_user INT(11);
  SET c_user=123;
  RETURN c_user;
  END//
  DELIMITER ;
-- ]]></query>

-- </queries>

