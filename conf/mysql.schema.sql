-- <queries>
--<do>
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
--</do>

-- <create_schema_and_user>
-- Example: not used in perl code
CREATE USER 'mydlje'@'localhost' IDENTIFIED BY  'mydljep';

GRANT USAGE ON * . * TO  'mydlje'@'localhost' IDENTIFIED BY  'mydljep' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;

CREATE DATABASE IF NOT EXISTS  `mydlje` ;

GRANT ALL PRIVILEGES ON  `mydlje` . * TO  'mydlje'@'localhost';
ALTER DATABASE  `mydlje` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
-- </create_schema_and_user>

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
  `properties` blob  COMMENT 'Serialized/cached properties inherited and overided from group',
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
  `namespace` set('site','cpanel') NOT NULL DEFAULT 'site' COMMENT 'site (outsiders), cpanel(insiders)',
  `created_by` int(11) NOT NULL DEFAULT '1' COMMENT 'id of who created this group?',
  `changed_by` int(11) NOT NULL DEFAULT '1' COMMENT 'id of who changed this group?',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  `start` int(11) NOT NULL DEFAULT '0',
  `stop` int(11) NOT NULL DEFAULT '0',
  `properties` blob  COMMENT 'Serialized/cached properties inherited by the users in this group',
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
  `session_data` blob NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cid` (`cid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COMMENT='Users sessions storage table' AUTO_INCREMENT=0 ;
-- </table>

-- <table name="my_content">
DROP TABLE IF EXISTS `my_content`;
CREATE TABLE IF NOT EXISTS `my_content` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary unique identyfier',
  `alias` varchar(255) NOT NULL DEFAULT 'seo friendly id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT 'Parent Question, Article, Note, Book ID etc',
  `user_id` int(11) NOT NULL DEFAULT '0',
  `sorting` int(10) NOT NULL DEFAULT '0' COMMENT 'suitable for sorting articles in a book',
  `data_type` set('page','question','answer','book','note','article','chapter') NOT NULL DEFAULT 'note' COMMENT 'Semantic Content Types. See MYDLjE::M::Content::*.',
  `data_format` set('text','html','markdown') NOT NULL DEFAULT 'text',
  `time_created` int(11) NOT NULL DEFAULT '0' COMMENT 'When this content was inserted',
  `tstamp` int(11) NOT NULL DEFAULT '0' COMMENT 'Last time the record was touched',
  `title` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  `keywords` varchar(255) NOT NULL DEFAULT '',
  `tags` varchar(100) NOT NULL DEFAULT '',
  `body` text NOT NULL,
  `invisible` tinyint(1) NOT NULL,
  `language` varchar(2) NOT NULL DEFAULT '',
  `groups` blob,
  `protected` char(1) NOT NULL DEFAULT '',
  `featured` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Show on top independently of other sorting.',
  `accepted` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Answer accepted?',
  `bad` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Reported as inapropriate offensive etc.',
  PRIMARY KEY (`id`),
  KEY `pid` (`pid`),
  KEY `tstamp` (`tstamp`),
  KEY `tags` (`tags`),
  KEY `user_id` (`user_id`),
  KEY `data_type` (`data_type`),
  UNIQUE KEY `alias` (`alias`),
  KEY `language` (`language`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='MYDLjE content elements. Types are used via views.' AUTO_INCREMENT=0 ;
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
  PRIMARY KEY (`property`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Properties for users and groups.';
-- </table>

-- <table name="my_user_properties">
DROP TABLE IF EXISTS `my_users_properties`;
CREATE TABLE IF NOT EXISTS `my_users_properties` (
  `uid` int(11) NOT NULL COMMENT 'User  ID',
  `property` varchar(30) NOT NULL COMMENT 'user property',
  `property_value` varchar(30) NOT NULL COMMENT 'value interperted depending on business logic',
  PRIMARY KEY (`uid`,`property`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Users owning properties.';
-- </table>

--
-- Views which will be used instead of directly my_content
-- Note: MySQL 5 required
-- 25.09.10 12:44
--
-- Note: from selects below are visible interdependencies
-- 26.09.10 20:43
-- TODO: make MYDLjE::M::Content wor automatically with views
-- when a database suports this.
-- EDITABLE VIEWS
--<view name="my_varticle">
DROP VIEW IF EXISTS  my_varticle;
CREATE OR REPLACE VIEW my_varticle as select 
    id,user_id,pid,sorting,data_type,
    data_format,time_created,tstamp,title,body,invisible,
    language,groups,protected,bad
from my_content where (data_type = 'article');
--</view>
--<view name="my_vchapter">
DROP VIEW IF EXISTS my_vchapter;
CREATE OR REPLACE VIEW my_vchapter as select
    id,user_id,pid,sorting,data_type,
    data_format,time_created,tstamp,title,body,invisible,
    language,groups,protected,bad
from my_content where (data_type = 'chapter');
--</view>
--<view name="my_vquestion">
DROP VIEW IF EXISTS my_vquestion;
CREATE OR REPLACE VIEW my_vquestion as select
    id,user_id,pid,data_type,
    data_format,time_created,tstamp,title,body,invisible,
    language,groups,protected,bad
from my_content where (data_type = 'question');
--</view>
-- Answers are children of questions so they do not need
-- groups,protected,title
--<view name="my_vanswer">
DROP VIEW IF EXISTS my_vanswer;
CREATE OR REPLACE VIEW my_vanswer as select 
    id,user_id,pid,data_type,
    data_format,time_created,tstamp,body,invisible,
    language,accepted,bad
from my_content where (data_type = 'answer');
--</view>
--<view name="my_vbook">
DROP VIEW IF EXISTS my_vbook;
CREATE OR REPLACE VIEW my_vbook as select
    id,user_id,pid,data_type,
    data_format,time_created,tstamp,title,body,invisible,
    language,groups,protected,bad
from my_content where (data_type = 'book');
--</view>
--<view name="my_vnote">
DROP VIEW IF EXISTS my_vnote;
CREATE OR REPLACE VIEW my_vnote as select
    id,user_id,pid,data_type,
    data_format,time_created,tstamp,title,body,invisible,
    language,bad
from my_content where (data_type = 'note');
--</view>
-- </queries>
