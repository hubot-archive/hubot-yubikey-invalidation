# Description:
#   Invalidates Yubikeys by sending them to (by default) Yubicloud when they
#   are accidentally pasted into a chat room.
#
# Configuration:
#   HUBOT_YUBIKEY_VALIDATION_URL: URL to the validation server. By default,
#   this is Yubicloud.
#
#   HUBOT_YUBIKEY_API_ID: API id and key for the validation server or
#   Yubicloud. For Yubicloud, generate one at
#   <https://upgrade.yubico.com/getapikey/>

defaultValidationUrl = "https://api.yubico.com/wsapi/2.0/verify"
validationUrl        = process.env.HUBOT_YUBIKEY_VALIDATION_URL || defaultValidationUrl
apiId                = process.env.HUBOT_YUBIKEY_API_ID

crypto = require 'crypto'
https  = require 'https'

module.exports = (robot) ->
  charset        = "cbdefghijklnrtuv"
  otpRegex       = new RegExp("^([#{charset}]{44})$")
  dvorakCharset  = "jxe.uidchtnbpygk"
  dvorakOtpRegex = new RegExp("^([#{dvorakCharset}]{44})$")

  generateNonce = ->
    crypto.pseudoRandomBytes(16).toString('hex')

  invalidateOtp = (msg, otp) ->
    https.get "#{validationUrl}?id=#{apiId}&otp=#{otp}&nonce=#{generateNonce()}", (res) ->
      if res.statusCode != 200
        msg.reply "I tried to invalidate that OTP for you, but I got a #{res.statusCode} error from the server :cry:"
      else
        msg.reply "Was that your Yubikey :trollface:? I went ahead and invalidated that OTP for you :lock:"

  invalidateDvorakOtp = (msg, dvorakOtp) ->
    otp = dvorakOtp
    for i in [0..dvorakCharset.length]
      otp = otp.replace(dvorakCharset[i], charset[i])

    invalidateOtp(msg, otp)

  missingEnviroment = (msg) ->
    missingSomething = false
    unless validationUrl?
      msg.send "Yubikey Validation URL is missing: ensure that HUBOT_YUBIKEY_VALIDATION_URL is set"
      missingSomething = true
    unless apiId?
      msg.send "Yubikey Api ID is missing: ensure that HUBOT_YUBIKEY_API_ID is set"
      missingSomething = true
    return missingSomething

  robot.hear otpRegex, (msg) ->
    return if missingEnviroment(msg)
    invalidateOtp(msg, msg.match[1])

  robot.hear dvorakOtpRegex, (msg) ->
    return if missingEnviroment(msg)
    invalidateDvorakOtp(msg, msg.match[1])
