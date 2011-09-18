-- <queries>

-- <query name="groups"><![CDATA[

INSERT INTO `groups` (
    `id`, `name`, `description`, `namespaces`, `created_by`, `changed_by`, `disabled`,
    `start`, `stop`, `properties`) VALUES
    (1, 'admin', 'Users belonging to this group have no access restrictions', 'MYDLjE::ControlPanel, MYDLjE::Site', 1, 1, 0, 0, 0, NULL),
    (2, 'guest', 'Only the guest user is in this group and has access only to the site.', 'MYDLjE::Site', 1, 1, 0, 0, 0, NULL),
    (3, 'customers', 'Default group for all registered users via site.', 'MYDLjE::Site', 1, 1, 0, 0, 0, NULL),
    (4, 'editors', 'Pages and Site Editors', 'MYDLjE::ControlPanel', 1, 1, 0, 0, 0, NULL);

-- ]]></query>

-- <query name="users"><![CDATA[

INSERT INTO `users` (`id`, `group_id`, `login_name`, `login_password`, `first_name`, `last_name`, `email`, `description`, `created_by`, `changed_by`, `tstamp`, `reg_tstamp`, `disabled`, `start`, `stop`, `properties`) VALUES
    (1, 1, 'admin', 'fea47bc9ac370bc470f0d0cdf657c533', 'Красимир', 'Беров', 'admin@localhost.com', 'Do not delete or use this user! He anyway can not log in since the password md5_sum is a random invalid password. Change his password if you wish.', 0, 1, 0, 0, 1, 0, 0, NULL),
    (2, 2, 'guest', 'fda87185f0186097655acb7beb954115', '', '', 'guest@localhost.com', 'Default not logged in user. Do not remove!', 1, 1, 0, 0, 0, 0, 0, NULL);

-- ]]></query>
-- <query name="user_group"><![CDATA[
 INSERT INTO `user_group` (`user_id`, `group_id`) VALUES (1, 1), (2, 2);
-- ]]></quey>

-- <query name="domains"><![CDATA[

INSERT INTO `domains` (`id`, `domain`, `name`, `description`, `user_id`, `group_id`, `permissions`, `published`) VALUES
(0, 'localhost', 'Local Host', 'Default domain for all pages in the system.', 1, 1, 'drwxrwxr-x', 2);

-- ]]></quey>

-- <query name="pages"><![CDATA[

INSERT INTO `pages` (`id`, `pid`, `domain_id`, `alias`, `page_type`, `sorting`, `template`, `cache`, `expiry`, `permissions`, `user_id`, `group_id`, `tstamp`, `start`, `stop`, `published`, `hidden`, `deleted`, `changed_by`) VALUES
(0, 0, 0, 'system_page-do_not_use_or_delete', '', 1, NULL, 0, 300, 'drwx------', 1, 1, 1, 1, 1, 2, 1, 1, 1);

-- ]]></quey>

-- <query name="content"><![CDATA[
INSERT INTO `content` (`id`, `alias`, `pid`, `page_id`, `user_id`, `group_id`, `sorting`, `data_type`, `data_format`, 
`time_created`, `tstamp`, `title`, `description`, `keywords`, `tags`, `body`, `language`, `permissions`, `featured`, 
`accepted`, `bad`, `deleted`,`start`, `stop`) VALUES
(0, 'system_content-do_not_use_or_delete', 0, 0, 1, 1, 0, 'note', 'text', 1, 1, 'Parent content of all contents', '', '', '', 'This content is used only to keep foreign key constraints happy.', 'en', 'drwx------', 0, 0, 0, 1, 1, 1);

-- ]]></quey>


-- ]]></queries>

