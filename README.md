hubot-sugarcrm
==============

hubot talks to SugarCRM. It provides a fluent API to your SugarCRM instance.

this work is inspired from https://github.com/github/hubot-scripts/blob/master/src/scripts/sugarcrm.coffee

This coffeescript is currently tested with a SugarCRM 5.5 Professional Edition

commands
========

your hubot will understand various commands.

crminfo
-------

it gets information from the server (like SugarCRM version, edition and local server time) and outputs it.

find
----

syntax: find module for field is|like content

example: find Leads for account_name like ACME
searches for records in module Leads where account_name LIKE '%ACME%'

example: find Leads for first_name is Tobias
searches for records in module Leads where first_name is Tobias