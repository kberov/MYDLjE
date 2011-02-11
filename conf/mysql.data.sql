-- <queries>
-- <my_users>
INSERT INTO `my_users` (`id`, `login_name`, `login_password`, `first_name`, `last_name`, `email`, `description`,
 `created_by`, `changed_by`, `disabled`, `start`, `stop`, `properties`) VALUES
(1, 'admin', 'fda87185f0186097655acb7beb954115', 'Красимир', 'Беров', 'admin@localhost', 
'Админстратор и създател на сайта', 0, 1, 0, 0, 0, '{"lang": "bg"}\r\n\r\n'),
(2, 'guest', 'fda87185f0186097655acb7beb954115', '', '', 'guest@localhost', 
'default not logged in user', 1, 1, 0, 0, 0, '{}');
-- </my_users>

-- <my_groups>
INSERT INTO `groups` (`id`, `name`, `description`, `namespace`, `created_by`, `changed_by`, `disabled`, `start`, `stop`, `properties`) VALUES
(1, 'guest', 'The guets user only is in this group', 'site', 1, 1, 0, 0, 0, ''),
(2, 'customers', 'In this group are all customers', 'site', 1, 1, 0, 0, 0, ''),
(3, 'editors', 'Pages and Site Editors', 'admin', 1, 1, 0, 0, 0, '---\r\n\r\nvalid_steps:\r\n\r\n  main: 1\r\n\r\n  edit_page: 1\r\n\r\n  tree_pages: 1\r\n\r\n  add_content: 1\r\n\r\n  edit_content: 1\r\n\r\n  delete_content: 1\r\n\r\n  list_content: 1\r\n\r\n  edit_cache: 1\r\n\r\n  list_languages: 1\r\n\r\n  edit_preferences: 1\r\n\r\n  tree_products: 1\r\n\r\n  tree_files: 1\r\n\r\n  login: 1\r\n\r\n  logout: 1\r\n\r\n');
-- </my_groups>

-- </queries>

