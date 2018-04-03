# Use the class methods to get down to business quickly
require 'httparty'
response = HTTParty.get('http://localhost:3000/entries')

puts response.body, response.code, response.message, response.headers.inspect
