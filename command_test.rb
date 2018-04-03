# Use the class methods to get down to business quickly
require 'httparty'

# HTTParty.post('http://localhost:3000/declarations.json', body: {content: 'testytesty'})

response = HTTParty.get('http://localhost:3000/declarations.json')

puts response.body
