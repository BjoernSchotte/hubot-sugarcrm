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

  robot.respond /crmfind (.+) for (.+) is (.+)/i, (msg) ->
    [module, field, query] = msg.match[1..3]
    msg.send "Searching in " + module + " where " + field + " like '%" + query + "%'"
    sugarCRMLogin msg, url, username, password, (session) ->
      sugarCRMSearchRecord msg, url, session, module, field, query, (data_result) ->
        #for key,value of data_result
        #  msg.send key + " - " + value
        #msg.send ""
        #msg.send "Now iterating through result list:"
        for entry in data_result.entry_list
        #  msg.send "ID: " + entry.id
          for key,value of entry
            msg.send key + " = " + value
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

sugarCRMSearchRecord = (msg, url, session, module, field, searchfor, callback) ->
  d_query = field + " LIKE '%" + searchfor + "%'"
  d_order_by = field # for future enhancement
  data = {
    session: session,
    module_name: module,
    query: d_query,
    order_by: d_order_by,
    select_fields: ["first_name", "last_name"]
  }
  sugarCRMCall msg, url, 'get_entry_list', data, (err, res, body) ->
    json    = JSON.parse(body)
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
