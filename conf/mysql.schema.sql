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
-- <table name="my_users">
DROP TABLE IF EXISTS `my_users`;
CREATE TABLE IF NOT EXISTS `my_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login_name` varchar(255) NOT NULL,
`login_password` varchar(100) NOT NULL COMMENT 'Mojo::Util::md5_sum($login_name.$login_password)',
  `first_name` varchar(255) NOT NULL DEFAULT '',
  `last_name` varchar(255) NOT NULL DEFAULT '',
  `email` varchar(255) NOT NULL DEFAULT 'email@site.com',
  `description` varchar(255) DEFAULT NULL,
  `created_by` int(11) NOT NULL DEFAULT '0',
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
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='This table stores the users';
-- </table>

-- <table name="my_groups">
DROP TABLE IF EXISTS `my_groups`;
CREATE TABLE IF NOT EXISTS `my_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  `namespace` set('site','cpanel') NOT NULL DEFAULT 'site' COMMENT 'site (outsiders), cpanel(insiders)',
  `created_by` int(11) NOT NULL DEFAULT '1' COMMENT 'id of who created this group?',
  `changed_by` int(11) NOT NULL DEFAULT '1' COMMENT 'id of who changed this group?',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  `start` int(11) NOT NULL DEFAULT '0',
  `stop` int(11) NOT NULL DEFAULT '0',
  `properties` blob COMMENT 'Serialized/cached properties inherited by the users in this group',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `created_by` (`created_by`),
  KEY `namespace` (`namespace`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
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

-- <table name="my_content">
DROP TABLE IF EXISTS `my_content`;
CREATE TABLE IF NOT EXISTS `my_content` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary unique identyfier',
  `alias` varchar(255) NOT NULL DEFAULT 'seo friendly id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT 'Parent Question, Article, Note, Book ID etc',
  `user_id` int(11) NOT NULL COMMENT 'User that created it initially.',
  `sorting` int(10) NOT NULL DEFAULT '0' COMMENT 'suitable for sorting articles in a book',
  `data_type` varchar(32) NOT NULL DEFAULT 'note' COMMENT 'Semantic Content Types. See MYDLjE::M::Content::*.',
  `data_format` set('text','textile','markdown','html','template') NOT NULL DEFAULT 'text',
  `time_created` int(11) NOT NULL DEFAULT '0' COMMENT 'When this content was inserted',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'Last time the record was touched',
  `title` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  `keywords` varchar(255) NOT NULL DEFAULT '',
  `tags` varchar(100) NOT NULL DEFAULT '',
  `body` text NOT NULL,
  `invisible` tinyint(1) NOT NULL,
  `language` varchar(2) NOT NULL DEFAULT '',
  `group_id` int(11) NOT NULL DEFAULT '1' COMMENT 'The group of this content.',
  `protected` char(1) NOT NULL DEFAULT '',
  `featured` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Show on top independently of other sorting.',
  `accepted` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Answer accepted?',
  `bad` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Reported as inapropriate offensive etc.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `alias` (`alias`,`data_type`),
  KEY `pid` (`pid`),
  KEY `tstamp` (`tstamp`),
  KEY `tags` (`tags`),
  KEY `user_id` (`user_id`),
  KEY `data_type` (`data_type`),
  KEY `language` (`language`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='MYDLjE content elements. Different  data_typeS may be used via views.';

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
-- TODO: make MYDLjE::M::Content wor automatically with views
-- when a database suports this.
-- EXAMPLE EDITABLE VIEWS
--<view name="my_varticle">
DROP VIEW IF EXISTS  my_varticle;
CREATE OR REPLACE VIEW my_varticle as select 
    id,user_id,pid,sorting,data_type,
    data_format,time_created,tstamp,title,body,invisible,
    language,group_id,protected,bad
from my_content where (data_type = 'article');
--</view>

-- </queries>
--<do id="constraints">
ALTER TABLE `my_content`
  ADD CONSTRAINT `my_content_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `my_users` (`id`);
ALTER TABLE `my_sessions`
  ADD CONSTRAINT `my_sessions_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `my_users` (`id`) ON UPDATE CASCADE;
ALTER TABLE `my_users_groups`
  ADD CONSTRAINT `my_users_groups_group_id_fk` FOREIGN KEY (`gid`) REFERENCES `my_groups` (`id`),
  ADD CONSTRAINT `my_users_groups_user_id_fk` FOREIGN KEY (`uid`) REFERENCES `my_users` (`id`);

--</do>
--<do id="enable_foreign_key_checks">
SET FOREIGN_KEY_CHECKS=1;
--</do>