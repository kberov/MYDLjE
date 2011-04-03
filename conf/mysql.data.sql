-- <queries>
-- <query name="my_users">
INSERT INTO `my_users` (
    `id`, `login_name`, `login_password`, `first_name`, `last_name`, `email`, `description`,
    `created_by`, `changed_by`, `tstamp`, `reg_tstamp`, `disabled`, `start`, `stop`, `properties`
    ) VALUES
    (1, 'admin', 'fda87185f0186097655acb7beb954115', 'Красимир', 'Беров', 'admin@localhost.com', 'Админстратор и създател на сайта',
    0, 1, 0, 0, 1, 0, 0, NULL),
    (2, 'guest', 'fda87185f0186097655acb7beb954115', '', '', 'guest@localhost.com', 'Default not logged in user. Do not remove!',
    1, 1, 0, 0, 0, 0, 0, NULL);
-- </query>

-- <query name="my_groups">

INSERT INTO `my_groups` (
    `id`, `name`, `description`, `namespace`, `created_by`, `changed_by`, `disabled`,
    `start`, `stop`, `properties`) VALUES
    (1, 'guest', 'The guets user only is in this group', 'site', 1, 1, 0, 0, 0, NULL),
    (2, 'customers', 'In this group are all customers (all registered users via site)', 'site', 1, 1, 0, 0, 0, NULL),
    (3, 'editors', 'Pages and Site Editors', 'cpanel', 1, 1, 0, 0, 0, NULL);
-- </query>

-- </queries>

