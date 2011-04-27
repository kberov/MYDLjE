-- <queries>

-- <query name="my_groups">

INSERT INTO `my_groups` (
    `id`, `name`, `description`, `namespaces`, `created_by`, `changed_by`, `disabled`,
    `start`, `stop`, `properties`) VALUES
    (1, 'admin', 'Users belonging to this group have no access restrictions', 'MYDLjE::ControlPanel, MYDLjE::Site', 1, 1, 0, 0, 0, NULL),
    (2, 'guest', 'The guets user only is in this group', 'MYDLjE::Site', 1, 1, 0, 0, 0, NULL),
    (3, 'customers', 'In this group are all customers (all registered users via site)', 'MYDLjE::Site', 1, 1, 0, 0, 0, NULL),
    (4, 'editors', 'Pages and Site Editors', 'MYDLjE::ControlPanel', 1, 1, 0, 0, 0, NULL);

-- </query>

-- <query name="my_users">

INSERT INTO `my_users` (`id`, `group_id`, `login_name`, `login_password`, `first_name`, `last_name`, `email`, `description`, `created_by`, `changed_by`, `tstamp`, `reg_tstamp`, `disabled`, `start`, `stop`, `properties`) VALUES
    (1, 1, 'admin', 'fea47bc9ac370bc470f0d0cdf657c533', 'Красимир', 'Беров', 'admin@localhost.com', 'Do not delete or use this user! He anyway can not log in since the password md5_sum is a random invalid password. Change his password if you wish.', 0, 1, 0, 0, 1, 0, 0, NULL),
    (2, 2, 'guest', 'fda87185f0186097655acb7beb954115', '', '', 'guest@localhost.com', 'Default not logged in user. Do not remove!', 1, 1, 0, 0, 0, 0, 0, NULL);

-- </query>

-- <query name="my_pages">

INSERT INTO `my_pages` (`id`, `pid`, `alias`, `page_type`, `sorting`, `template`, `cache`, `expiry`, `permissions`, `user_id`, `group_id`, `tstamp`, `start`, `stop`, `published`, `deleted`, `changed_by`) VALUES
    (0, 0, 'dummy_page-do_not_use_or_delete', '', 1, NULL, 0, 300, 'drwx------', 1, 1, 1, 1, 1, 0, 1, 1);

-- </quey>

-- <query name="my_content">
INSERT INTO `my_content` (`id`, `alias`, `pid`, `page_id`, `user_id`, `sorting`, `data_type`, `data_format`, `time_created`, `tstamp`, `title`, `description`, `keywords`, `tags`, `body`, `language`, `group_id`, `permissions`, `featured`, `accepted`, `bad`, `deleted`,`start`, `stop`) VALUES
(0, 'dummy_content-do_not_use_or_delete', 0, 0, 1, 0, 'note', 'text', 1, 1, 'Parent content of all contents', '', '', '', 'This content is used only to keep foreign key constraints happy.', 'en', 1, 'drwx------', 0, 0, 0, 1, 1, 1);

-- </quey>

-- <query name="my_users_groups">
 INSERT INTO `my_users_groups` (`uid`, `gid`) VALUES (1, 1), (2, 2);
-- </quey>

-- </queries>

