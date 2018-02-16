require('env2')('.env')

const redis = require('redis')
const nlp = require('compromise')
const Guardian = require('guardian-js')

const api = new Guardian(process.env.GUARDIAN_API_KEY, false)
const client = redis.createClient()
