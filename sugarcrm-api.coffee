# hubot speaking to SugarCRM
#
# (C) Björn Schotte
# License: MIT License
#
# set your env vars:
#
# HUBOT_SUGARCRM_URL = "http://crmhost.example.com"
# HUBOT_SUGARCRM_USERNAME = "johndoe"
# HUBOT_SUGARCRM_PASSWORD = "cleartextpw"

module.exports = (robot) ->
  url          = process.env.HUBOT_SUGARCRM_URL
  username     = process.env.HUBOT_SUGARCRM_USERNAME
  password     = process.env.HUBOT_SUGARCRM_PASSWORD

  lead_fields  = ["first_name", "last_name", "phone_work", "account_name"]

  unless url
    msg.send "SugarCRM URL isn't set."
    msg.send "Please set the HUBOT_SUGARCRM_URL environment variable without prefixed HTTP or trailing slash"
    return

  unless username
    msg.send "SugarCRM username isn't set."
    msg.send "Please set the HUBOT_SUGARCRM_USERNAME environment variable"
    return

  unless password
    msg.send "SugarCRM password isn't set."
    msg.send "Please set the HUBOT_SUGARCRM_PASSWORD environment variable"
    return


  robot.respond /hellocrm/i, (msg) ->
    msg.send "hello you"

  robot.respond /crminfo/i, (msg) ->
    sugarCRMLogin msg, url, username, password, (session) ->
      data = {
      session: session
      }
      sugarCRMCall msg, url, 'get_server_info', data, (err, res, body) ->
        json          = JSON.parse(body)
        msg.send "This is your current SugarCRM installation: " + json.version + " " + json.flavor
        msg.send "Time on server: " + json.gmt_time
        # for key,value of json
        #   msg.send key + " - " + value

  robot.respond /find (.+) for (.+) (is|like) (.+)/i, (msg) ->
    [module, field, operator, query] = msg.match[1..4]
    # msg.send "Searching in " + module + " where " + field + " " + operator + " '%" + query + "%'"
    sugarCRMLogin msg, url, username, password, (session) ->
      sugarCRMSearchRecord msg, url, session, module, field, operator, query, (data_result) ->
        for entry in data_result.entry_list
          id = entry.id
          sugarCRMGetEntry msg, url, session, module, id, lead_fields, (entry_result) ->
            # currently only works for module Leads
            # TODO: make field names dependant on queried module
            record = entry_result.entry_list[0]
            record_fields = record.name_value_list
            first_name = record_fields.first_name.value
            last_name = record_fields.last_name.value
            phone_work = record_fields.phone_work.value
            account_name = record_fields.account_name.value
            msg.send first_name + " " + last_name + " " + phone_work + " [" + account_name + "]"
        #  msg.send "ID: " + entry.id
        #  for key,value of entry
        #    msg.send key + " = " + value
        #  msg.send entry.first_name + " " + entry.last_name + " at " + entry.account_name + ". Phone: " + entry.phone_work

sugarCRMLogin = (msg, url, user_name, password, callback) ->
  crypto = require('crypto')
  hashedPassword = crypto.createHash('md5').update(password).digest("hex")
  data = {
    user_auth: {
      user_name: user_name,
      password: hashedPassword
    }
  }
  sugarCRMCall msg, url, 'login', data, (err, res, body) ->
    sessionID = JSON.parse(body).id
    callback(sessionID)

sugarCRMSearchRecord = (msg, url, session, module, field, operator, searchfor, callback) ->
  if operator == "is"
    # we need to attach module here
    # i.e. Leads.first_name in order to avoid ambigoous field name errors in the SQL query
    d_query = module.toLowerCase() + "." + field + "= '" + searchfor + "'"
  else if operator == "like"
    d_query = module.toLowerCase() + "." + field + " LIKE '%" + searchfor + "%'"

  # msg.send module + " Query = " + d_query
  d_order_by = field # for future enhancement
  data = {
    session: session,
    module_name: module,
    query: d_query,
    order_by: d_order_by,
  }
  sugarCRMCall msg, url, 'get_entry_list', data, (err, res, body) ->
    # debugging
    # msg.send "err: " + err
    # msg.send "res: " + res
    # msg.send "body: " + JSON.stringify body
    json    = JSON.parse(body)
    callback(json)

sugarCRMGetEntry = (msg, url, session, module, id, fields, callback) ->
  data = {
    session: session,
    module_name: module,
    id: id,
    select_fields: fields
  }
  sugarCRMCall msg, url, 'get_entry', data, (err, res, body) ->
    json  = JSON.parse(body)
    callback(json)

sugarCRMCall = (msg, url, method, data, callback) ->
  msg.http(url + '/service/v2/rest.php')
    .header('Content-Length', 0)
    .query
      method: method,
      input_type: 'JSON',
      response_type: 'JSON',
      rest_data: JSON.stringify data
    .post() (err, res, body) ->
      callback(err, res, body)
