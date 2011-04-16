-- <queries>
-- <query name="my_users">
INSERT INTO `my_users` (
    `id`, `login_name`, `login_password`, `first_name`, `last_name`, `email`, `description`,
    `created_by`, `changed_by`, `tstamp`, `reg_tstamp`, `disabled`, `start`, `stop`, `properties`
    ) VALUES
    (1, 'admin', 'fea47bc9ac370bc470f0d0cdf657c533', 'Красимир', 'Беров', 'admin@localhost.com', 'Do not delete or use this user! He anyway can not log in since the password md5_sum is a random invalid password. Change his password if you insist.', 0, 1, 0, 0, 1, 0, 0, NULL),
    (2, 'guest', 'fda87185f0186097655acb7beb954115', '', '', 'guest@localhost.com', 'Default not logged in user. Do not remove!', 1, 1, 0, 0, 0, 0, 0, NULL);

-- </query>

-- <query name="my_groups">

INSERT INTO `my_groups` (
    `id`, `name`, `description`, `namespace`, `created_by`, `changed_by`, `disabled`,
    `start`, `stop`, `properties`) VALUES
    (1, 'admin', 'Users belonging to this group have no access restrictions', 'cpanel', 1, 1, 0, 0, 0, NULL),
    (2, 'guest', 'The guets user only is in this group', 'site', 1, 1, 0, 0, 0, NULL),
    (3, 'customers', 'In this group are all customers (all registered users via site)', 'site', 1, 1, 0, 0, 0, NULL),
    (4, 'editors', 'Pages and Site Editors', 'cpanel', 1, 1, 0, 0, 0, NULL);

-- </query>

-- <query name="my_users_groups">
INSERT INTO `my_users_groups` (`uid`, `gid`) VALUES (1, 1), (2, 2);
-- </quey>
-- </queries>

