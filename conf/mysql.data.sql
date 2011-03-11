-- <queries>
-- <query name="my_users">
INSERT INTO `my_users` (`login_name`, `login_password`, `first_name`, `last_name`, `email`, `description`,
 `created_by`, `changed_by`, `disabled`, `start`, `stop`) VALUES
('admin', 'fda87185f0186097655acb7beb954115', 'Красимир', 'Беров', 'admin@localhost', 
'Админстратор и създател на сайта', 0, 1, 0, 0, 0),
('guest', 'fda87185f0186097655acb7beb954115', '', '', 'guest@localhost', 
'Default not logged in user.Do not remove.', 1, 1, 0, 0, 0);
-- </query>

-- <query name="my_groups">
INSERT INTO `my_groups` (`name`, `description`, `namespace`, `created_by`, `changed_by`, `disabled`, `start`, `stop`) VALUES
('guest', 'The guets user only is in this group', 'site', 1, 1, 0, 0, 0 ),
('customers', 'In this group are all customers', 'site', 1, 1, 0, 0, 0 ),
('editors', 'Pages and Site Editors', 'cpanel', 1, 1, 0, 0, 0);
-- </query>

-- </queries>

