-- <queries>

-- <create_schema_and_user>
-- Example: not used in perl code
CREATE USER 'mydlje'@'localhost' IDENTIFIED BY  'mydljep';

GRANT USAGE ON * . * TO  'mydlje'@'localhost' IDENTIFIED BY  'mydljep' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;

CREATE DATABASE IF NOT EXISTS  `mydlje` ;

GRANT ALL PRIVILEGES ON  `mydlje` . * TO  'mydlje'@'localhost';
ALTER DATABASE  `mydlje` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
-- </create_schema_and_user>
-- <do id="disable_foreign_key_checks">
SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- </do>
-- <table name="my_groups">
DROP TABLE IF EXISTS `my_groups`;
CREATE TABLE IF NOT EXISTS `my_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  `namespaces` varchar(255) NOT NULL DEFAULT 'MYDLjE::Site' COMMENT 'MYDLjE::Site (outsiders), MYDLjE::ControlPanel (insiders)',
  `created_by` int(11) NOT NULL DEFAULT '1' COMMENT 'id of who created this group.',
  `changed_by` int(11) NOT NULL DEFAULT '1' COMMENT 'id of who changed this group.',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  `start` int(11) NOT NULL DEFAULT '0',
  `stop` int(11) NOT NULL DEFAULT '0',
  `properties` blob COMMENT 'Serialized/cached properties inherited by the users in this group',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `created_by` (`created_by`),
  KEY `namespaces` (`namespaces`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
-- </table>

-- <table name="my_users">
DROP TABLE IF EXISTS `my_users`;
CREATE TABLE IF NOT EXISTS `my_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL COMMENT 'Primary group for this user',
  `login_name` varchar(100) NOT NULL,
  `login_password` varchar(100) NOT NULL COMMENT 'Mojo::Util::md5_sum($login_name.$login_password)',
  `first_name` varchar(255) NOT NULL DEFAULT '',
  `last_name` varchar(255) NOT NULL DEFAULT '',
  `email` varchar(255) NOT NULL DEFAULT 'email@site.com',
  `description` varchar(255) DEFAULT NULL,
  `created_by` int(11) NOT NULL DEFAULT '1'  COMMENT 'id of who created this user.',
  `changed_by` int(11) NOT NULL DEFAULT '1' COMMENT 'Who modified this user the last time?',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'last modification time',
  `reg_tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'registration time',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  `start` int(11) NOT NULL DEFAULT '0',
  `stop` int(11) NOT NULL DEFAULT '0',
  `properties` blob COMMENT 'Serialized/cached properties inherited and overided from group',
  PRIMARY KEY (`id`),
  UNIQUE KEY `login_name` (`login_name`),
  UNIQUE KEY `email` (`email`),
  KEY `group_id` (`group_id`),
  KEY `reg_tstamp` (`reg_tstamp`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='This table stores the users';
-- </table>


-- <table name="my_sessions">
DROP TABLE IF EXISTS `my_sessions`;
CREATE TABLE IF NOT EXISTS `my_sessions` (
  `id` varchar(32) NOT NULL DEFAULT '' COMMENT 'md5_sum-med session id',
  `cid` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Count ID - number of unique visitors so far.',
  `user_id` int(11) NOT NULL COMMENT 'Which user is this session for?',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'Last modification time - last visit.',
  `sessiondata` blob NOT NULL COMMENT 'Session data freezed with Storable and packed with Base64',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cid` (`cid`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Users sessions storage table';
-- </table>

-- <table name="my_pages">
DROP TABLE IF EXISTS `my_pages`;
CREATE TABLE IF NOT EXISTS `my_pages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT 'Parent page id',
  `alias` varchar(32) NOT NULL DEFAULT '' COMMENT 'Alias for the page which may be used instead of the id ',
  `page_type` varchar(32) NOT NULL COMMENT 'Regular,Folder, Site Root etc',
  `sorting` int(11) NOT NULL DEFAULT '1',
  `template` text COMMENT 'TT2 code to display this page. Default template is used if not specified.',
  `cache` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1=yes 0=no',
  `expiry` int(11) NOT NULL DEFAULT '86400' COMMENT 'expiry tstamp if cache==1',
  `permissions` varchar(10) NOT NULL DEFAULT '-rwxr--r--' COMMENT 'Page editing permissions',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT 'owner',
  `group_id` int(11) NOT NULL DEFAULT '0' COMMENT 'owner group',
  `tstamp` int(11) NOT NULL DEFAULT '0',
  `start` int(11) DEFAULT '0',
  `stop` int(11) DEFAULT '0',
  `published` int(11) NOT NULL DEFAULT '0' COMMENT '0=not published,1=waiting,2=published',
  `hidden` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Is this page hidden? 0=No, 1=Yes',
  `deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT 'Is this page deleted? 0=No, 1=Yes',
  `changed_by` int(11) NOT NULL COMMENT 'Who modified this page the last time?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `alias` (`alias`),
  KEY `tstamp` (`tstamp`),
  KEY `page_type` (`page_type`),
  KEY `hidden` (`hidden`),
  KEY `pid` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Pages holding various content elements';

-- </table>

-- <table name="my_content">


DROP TABLE IF EXISTS `my_content`;
CREATE TABLE IF NOT EXISTS `my_content` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary unique identyfier',
  `alias` varchar(255) NOT NULL DEFAULT 'seo-friendly-id' COMMENT 'Unidecoded, lowercased and trimmed of \\W characters unique identifier for the row data_type',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT 'Parent Question, Article, Note, Book ID etc',
  `page_id` int(11) NOT NULL DEFAULT '0' COMMENT 'page.id to which this content belongs. Default: 0 ',
  `user_id` int(11) NOT NULL COMMENT 'User that created it initially.',
  `sorting` int(10) NOT NULL DEFAULT '0' COMMENT 'For sorting chapters in a book, pages in a menu etc.',
  `data_type` varchar(32) NOT NULL DEFAULT 'note' COMMENT 'Semantic Content Types. See MYDLjE::M::Content::*.',
  `data_format` varchar(32) NOT NULL DEFAULT 'text' COMMENT 'Corresponding engine will be used to process the content before output. Ie Text::Textile for textile.',
  `time_created` int(11) NOT NULL DEFAULT '0' COMMENT 'When this content was inserted',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'Last time the record was touched',
  `title` varchar(255) NOT NULL DEFAULT '' COMMENT 'Used in title html tag for pages or or as h1 for other data types.',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT 'Used in description meta tag when appropriate.',
  `keywords` varchar(255) NOT NULL DEFAULT '' COMMENT 'Used in keywords meta tag.',
  `tags` varchar(100) NOT NULL DEFAULT '' COMMENT 'Used in tag cloud boxes. merged with keywords and added to keywords meta tag.',
  `body` text NOT NULL COMMENT 'Main content when applicable.',
  `language` varchar(2) NOT NULL DEFAULT 'en' COMMENT 'Language of this content. All languages when empty string',
  `group_id` int(11) NOT NULL DEFAULT '1' COMMENT 'Group ID of the owner of this content.',
  `permissions` char(10) NOT NULL DEFAULT '-rwxr-x---' COMMENT 'duuugggooo - Experimental permissions for the content.',
  `featured` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Show on top independently of other sorting.',
  `accepted` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Answer accepted?',
  `bad` tinyint(2) NOT NULL DEFAULT '0' COMMENT 'Reported as inapropriate offensive etc. higher values -very bad.',
  `deleted` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'When set to 1 the record is not visible anywhere.',
  `start` int(11) NOT NULL COMMENT 'Date/Time from which the record will be accessible in the site.',
  `stop` int(11) NOT NULL COMMENT 'Date/Time till which the record will be accessible in the site.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `alias` (`alias`,`data_type`),
  KEY `pid` (`pid`),
  KEY `tstamp` (`tstamp`),
  KEY `tags` (`tags`),
  KEY `permissions` (`permissions`),
  KEY `user_id` (`user_id`),
  KEY `data_type` (`data_type`),
  KEY `language` (`language`),
  KEY `page_id` (`page_id`),
  KEY `deleted` (`deleted`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='MYDLjE content elements. Different  data_typeS may be used.';

-- </table>

-- <table name="my_users_groups">
DROP TABLE IF EXISTS `my_users_groups`;
CREATE TABLE IF NOT EXISTS `my_users_groups` (
  `uid` int(11) NOT NULL COMMENT 'User  ID',
  `gid` int(11) NOT NULL COMMENT 'Group ID',
  PRIMARY KEY (`uid`,`gid`),
  KEY `gid` (`gid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Which user to which group belongs';
-- </table>

-- <table name="my_properties">
DROP TABLE IF EXISTS `my_properties`;
CREATE TABLE IF NOT EXISTS `my_properties` (
  `property` varchar(30) NOT NULL COMMENT 'group or/and user property',
  `description` varchar(255) NOT NULL COMMENT 'What this property means?',
  `default_value` varchar(255) NOT NULL DEFAULT '' COMMENT 'Default value for this property?',
  PRIMARY KEY (`property`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Properties which can be used as permissions, capabilities or whatever business logic you put in.';
-- </table>

-- <table name="my_user_properties">

DROP TABLE IF EXISTS `my_users_properties`;
CREATE TABLE IF NOT EXISTS `my_users_properties` (
  `uid` int(11) NOT NULL COMMENT 'User  ID',
  `property` varchar(30) NOT NULL COMMENT 'user property',
  `property_value` varchar(30) NOT NULL COMMENT 'Value interperted depending on business logic',
  PRIMARY KEY (`uid`,`property`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Users owning properties.';
-- </table>

--
-- Views which will be used instead of directly my_content
-- Note: MySQL 5 required
-- 03.04.11 20:00
--
-- Note: from selects below are visible interdependencies
-- 
-- TODO: make MYDLjE::M::Content work automatically with views
-- when a database suports this.
-- EXAMPLE EDITABLE VIEWS
--<view name="my_vguest_content"><![CDATA[
CREATE OR REPLACE VIEW my_vguest_content AS SELECT 
`id`, `alias`, `pid`, `page_id`, `user_id`, `sorting`, `data_type`, `data_format`, `time_created`, `tstamp`, `title`, `description`, `keywords`, `tags`, `body`, `language`, `group_id`, `permissions`, `featured`, `accepted`, `bad`
FROM my_content WHERE(
  deleted = 0 AND (
    (start = 0 OR start < UNIX_TIMESTAMP()) AND (STOP = 0 OR STOP > UNIX_TIMESTAMP())
  )
  AND `permissions` LIKE '%r__'
);
--]]></view>

--<view name="my_varticle">
DROP VIEW IF EXISTS  my_varticle;

--</view>

-- </queries>
--<do id="constraints">
ALTER TABLE `my_pages`
  ADD CONSTRAINT `my_pages_id_fk` FOREIGN KEY (`pid`) REFERENCES `my_pages` (`id`) ON UPDATE CASCADE;
ALTER TABLE `my_content`
  ADD CONSTRAINT `my_content_page_id_fk` FOREIGN KEY (`page_id`) REFERENCES `my_pages` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `my_content_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `my_users` (`id`);

ALTER TABLE `my_sessions`
  ADD CONSTRAINT `my_sessions_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `my_users` (`id`) ON UPDATE CASCADE;
ALTER TABLE `my_users`
  ADD CONSTRAINT `my_users_group_id_fk` FOREIGN KEY (`group_id`) REFERENCES `my_groups` (`id`);

ALTER TABLE `my_users_groups`
  ADD CONSTRAINT `my_users_groups_group_id_fk` FOREIGN KEY (`gid`) REFERENCES `my_groups` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `my_users_groups_user_id_fk` FOREIGN KEY (`uid`) REFERENCES `my_users` (`id`) ON DELETE CASCADE ;

--</do>
--<do id="enable_foreign_key_checks">
SET FOREIGN_KEY_CHECKS=1;
--</do>