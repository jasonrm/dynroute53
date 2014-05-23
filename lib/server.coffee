# Node
http = require 'http'
path = require 'path'

# Libs
express = require 'express'
morgan = require 'morgan'
auth = require 'basic-auth'
Route53 = require 'nice-route53'

# source: http://stackoverflow.com/a/2548133/31341
endsWith = (str, suffix) ->
    return str.indexOf(suffix, str.length - suffix.length) != -1

findZoneForHostname = (r53, hostname, cb) ->
    # TODO : Cache Zones
    r53.zones (err, zones) ->
        if err
            return cb err
        for zone in zones
            if endsWith hostname, zone.name
                return cb null, zone.zoneId
        cb()

handleRequest = (req, res) ->
    user = auth(req)
    if user
        access_key_id = user.name
        secret_access_key = user.pass
    else if req.query.domain and req.query.password
        access_key_id = req.query.domain
        secret_access_key = req.query.password
    else if req.query.user and req.query.pass
        access_key_id = req.query.user
        secret_access_key = req.query.pass
    else
        res.statusCode = 403
        return res.end 'badauth'


    r53 = new Route53 {
        accessKeyId: access_key_id
        secretAccessKey: secret_access_key
    }

    hostname = req.query.hostname || req.query.host || req.query.id
    ip = req.query.ip || req.query.myip

    findZoneForHostname r53, hostname, (err, zoneID) ->
        if err
            res.statusCode = 403
            return res.end 'badauth'

        unless zoneID
            res.statusCode = 404
            return res.end 'nohost'

        record = {
            zoneId : zoneID
            name   : hostname
            type   : 'A',
            ttl    : 600,
            values : [ip]
        }
        r53.setRecord record, (err, recordStatus) ->
            if err or !(recordStatus?.status is 'INSYNC' or recordStatus?.status is 'PENDING')
                res.statusCode = 503
                return res.end()
            res.end 'good'

app = express()
app.use morgan()
app.use handleRequest
app.listen process.env.PORT || 8080
