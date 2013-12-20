# Description:
#   Returns title and description when links are posted
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_EMBEDLY_API_KEY - API key for use with embed.ly
#   HUBOT_HTTP_INFO_IGNORE_URLS - RegEx used to exclude Urls
#   HUBOT_HTTP_INFO_IGNORE_USERS - Comma-separated list of users to ignore
#
# Commands:
#   http(s)://<site> - prints the title and meta description for sites linked.
#
# Author:
#   Dave Reid

# Todo use https://github.com/embedly/embedly-node ?
#embedly = require('embedly')

module.exports = (robot) ->
  ignoredusers = []
  if process.env.HUBOT_HTTP_INFO_IGNORE_USERS?
    ignoredusers = process.env.HUBOT_HTTP_INFO_IGNORE_USERS.split(',')

  robot.hear /(http(?:s?):\/\/(\S*))/i, (msg) ->
    url = msg.match[1]

    username = msg.message.user.name
    if username in ignoredusers
      console.log("Ignoring user %s due to blacklist.", username)
      return

    # filter out some common files from trying
    if url.match(/\.(png|jpg|jpeg|gif|txt|zip|tar\.bz|js|css)/)
      return

    ignorePattern = process.env.HUBOT_HTTP_INFO_IGNORE_URLS
    if ignorePattern and url.match(ignorePattern)
      return

    msg
      .http("http://api.embed.ly/1/oembed")
      .query
        key: process.env.HUBOT_EMBEDLY_API_KEY
        url: url
        format: 'json'
        chars: 80
      .header('User-Agent', 'hubot-longurl')
      .get() (err, res, body) ->
        if err
          console.log("Error: #{err}")
        else
          response = JSON.parse body
          #console.log(response)
          if response.type is 'error'
            console.log("Error: #{response.error_message}")
            
          else
            reply = []
            
            # Ignore differences in trailing slashes or http vs https
            original_url = url.replace(/^(http(?:s?):\/\/)/i, '').replace(/\/$/, '')
            new_url = response.url.replace(/^(http(?:s?):\/\/)/i, '').replace(/\/$/, '')
            if original_url isnt new_url
              reply.push(response.url)
              
            if response.title
              reply.push(response.title)
              
            if response.description
              #reply.push(response.description)
              
            if reply.length
              msg.send reply.join(' | ')