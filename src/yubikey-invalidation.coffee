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
  otpRegex       = new RegExp("(cccccc[#{charset}]{38})$")
  dvorakCharset  = "jxe.uidchtnbpygk"
  dvorakOtpRegex = new RegExp("(jjjjjj[#{dvorakCharset}]{38})$")

  messagePrefix = "Was that your YubiKey?"

  generateNonce = ->
    crypto.pseudoRandomBytes(16).toString('hex')

  invalidateOtp = (msg, otp) ->
    https.get "#{validationUrl}?id=#{apiId}&otp=#{otp}&nonce=#{generateNonce()}", (res) ->
      if res.statusCode != 200
        msg.reply "#{messagePrefix} I tried to invalidate that OTP for you, but I got a #{res.statusCode} error from the server 😢"
      else
        msg.reply "#{messagePrefix} I went ahead and invalidated that OTP for you 🔒 You can disable accidental OTP triggers via https://support.yubico.com/hc/en-us/articles/360013714379-Accidentally-Triggering-OTP-Codes-with-Your-Nano-YubiKey"

  invalidateDvorakOtp = (msg, dvorakOtp) ->
    otp = dvorakOtp
    for i in [0..dvorakCharset.length]
      otp = otp.replace(dvorakCharset[i], charset[i])

    invalidateOtp(msg, otp)

  missingEnviroment = (msg) ->
    missingSomething = false
    unless apiId?
      msg.reply "#{messagePrefix} I'd like to invalidate that OTP for you, but I'm missing the HUBOT_YUBIKEY_API_ID environment variable. Maybe your local hubot maintainer can help you?"
      missingSomething = true
    return missingSomething

  robot.hear otpRegex, (msg) ->
    return if missingEnviroment(msg)
    invalidateOtp(msg, msg.match[1])

  robot.hear dvorakOtpRegex, (msg) ->
    return if missingEnviroment(msg)
    invalidateDvorakOtp(msg, msg.match[1])
