-- <queries>
--<do>
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
--</do>

-- <create_schema_and_user>
CREATE USER 'mydlje'@'localhost' IDENTIFIED BY  'mydljep';

GRANT USAGE ON * . * TO  'mydlje'@'localhost' IDENTIFIED BY  'mydljep' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;

CREATE DATABASE IF NOT EXISTS  `mydlje` ;

GRANT ALL PRIVILEGES ON  `mydlje` . * TO  'mydlje'@'localhost';
ALTER DATABASE  `mydlje` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
-- </create_schema_and_user>

DROP TABLE IF EXISTS `my_content`;
CREATE TABLE IF NOT EXISTS `my_content` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary unique identyfier',
  `user_id` int(11) NOT NULL DEFAULT '0',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT 'Parent Question, Article, Note, Book ID etc',
  `sorting` int(10) NOT NULL DEFAULT '0' COMMENT 'suitable for sorting articles in a book',
  `data_type` set('question','answer','book','note','article','chapter') NOT NULL DEFAULT 'note' COMMENT 'data type',
  `data_format` set('text','html','markdown') NOT NULL DEFAULT 'text',
  `time_created` int(11) NOT NULL DEFAULT '0' COMMENT 'When this content was inserted',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'Last time the record was touched',
  `title` varchar(255) NOT NULL DEFAULT '',
  `body` text NOT NULL,
  `invisible` tinyint(4) NOT NULL,
  `language` varchar(2) NOT NULL DEFAULT '',
  `groups` blob,
  `protected` char(1) NOT NULL DEFAULT '',
  `accepted` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Answer accepted?',
  `bad` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Reported as inapropriate offensive etc.',
  PRIMARY KEY (`id`),
  KEY `pid` (`pid`,`data_type`),
  KEY `tstamp` (`tstamp`,`title`),
  KEY `user_id` (`user_id`),
  KEY `language` (`language`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COMMENT='BGCC content elements. Types are used via views.' AUTO_INCREMENT=20 ;

-- <table name="my_users">
DROP TABLE IF EXISTS `my_users`;
CREATE TABLE IF NOT EXISTS `my_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login_name` varchar(255) NOT NULL DEFAULT '',
  `login_password` varchar(100) NOT NULL,
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
  `properties` text COMMENT 'User properties serialized in a JSON structure. ',
  PRIMARY KEY (`id`),
  UNIQUE KEY `login_name` (`login_name`),
  UNIQUE KEY `email` (`email`),
  KEY `created_by` (`created_by`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='This table stores the users' AUTO_INCREMENT=0 ;
-- </table>

-- <table name="my_groups">
DROP TABLE IF EXISTS `my_groups`;
CREATE TABLE IF NOT EXISTS `my_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  `namespace` set('site','admin') NOT NULL DEFAULT 'site' COMMENT 'site (outsiders), admin(insiders)',
  `created_by` int(11) NOT NULL DEFAULT '1' COMMENT 'id of who created this group?',
  `changed_by` int(11) NOT NULL DEFAULT '1' COMMENT 'id of who changed this group?',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  `start` int(11) NOT NULL DEFAULT '0',
  `stop` int(11) NOT NULL DEFAULT '0',
  `properties` text COMMENT 'Default properties for users  (members of this group) serialized in a JSON structure. ',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `created_by` (`created_by`),
  KEY `namespace` (`namespace`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0 ;
-- </table>

-- <table name="my_sessions">
DROP TABLE IF EXISTS `my sessions`;
CREATE TABLE IF NOT EXISTS `my_sessions` (
  `id` varchar(32) NOT NULL DEFAULT '',
  `cid` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Count ID',
  `user_id` int(11) NOT NULL COMMENT 'Which user is this session for?',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'last modification time',
  `a_session` blob NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cid` (`cid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COMMENT='Users sessions storage table' AUTO_INCREMENT=0 ;
-- </table>

-- <table name="my_content">
DROP TABLE IF EXISTS `my_content`;
CREATE TABLE IF NOT EXISTS `my_content` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary unique identyfier',
  `user_id` int(11) NOT NULL DEFAULT '0',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT 'Parent Question, Article, Note, Book ID etc',
  `sorting` int(10) NOT NULL DEFAULT '0' COMMENT 'suitable for sorting articles in a book',
  `data_type` set('question','answer','book','note','article','chapter') NOT NULL DEFAULT 'note' COMMENT 'data type',
  `data_format` set('text','html','markdown') NOT NULL DEFAULT 'text',
  `time_created` int(11) NOT NULL DEFAULT '0' COMMENT 'When this content was inserted',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'Last time the record was touched',
  `title` varchar(255) NOT NULL DEFAULT '',
  `body` text NOT NULL,
  `invisible` tinyint(4) NOT NULL,
  `language` varchar(2) NOT NULL DEFAULT '',
  `groups` blob,
  `protected` char(1) NOT NULL DEFAULT '',
  `accepted` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Answer accepted?',
  `bad` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Reported as inapropriate offensive etc.',
  PRIMARY KEY (`id`),
  KEY `pid` (`pid`,`data_type`),
  KEY `tstamp` (`tstamp`,`title`),
  KEY `user_id` (`user_id`),
  KEY `language` (`language`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COMMENT='BGCC content elements. Types are used via views.' AUTO_INCREMENT=20 ;
-- </table>

-- </queries>
