# -*- coding: utf-8 -*-
require "redd"
require 'yaml'
#require "dotenv"

#Dotenv.load
SUBREDDIT = 'girlgamerscss'

# Authorization
reddit = Redd.it(
  :script,
  'ID',
  'SECRET',
  'ACCOUNT',
  'PASS',
  user_agent: "yesss this is me 0.0.1"
)
reddit.authorize!

@subreddit = reddit.subreddit_from_name(SUBREDDIT)
@beaconFilePath = 'beacons.yml'

def getCurrentBeacons()
  beaconFile = YAML::load_file(@beaconFilePath)
  @beacons   = beaconFile || []
end

def isValid(gameData)
  @beacons.each do |beacon|
    #puts beacon[:data][:author], 'author'
    isExpired = pastExpiration(gameData[:createdAt])

    puts (beacon[:data][:author] == gameData[:author]) or isExpired

    if ((beacon[:data][:author] == gameData[:author]) or isExpired)
      return false
    end
  end
end

def getNewBeacons()
  posts = @subreddit.search('[LFG]')

  posts.each do |post|
    gameData = Hash[ *post.selftext.sub( /\n/, '' ).split(/\s*([^,]+:)\s+/)[1..-1] ]

    gameData[:game]      = gameData['Game:'][0..-2]
    gameData[:time]      = gameData['Time:'][0..-2]
    gameData[:contact]   = gameData['Contact:']
    gameData[:author]    = post.author
    gameData[:url]       = post.url
    gameData[:createdAt] = Time.at(post.created_utc)

    gameData.delete('Game:')
    gameData.delete('Time:')
    gameData.delete('Contact:')

    if isValid(gameData)
      puts 'creating a new beacon'
      createBeacon(gameData)
    end
  end
end

def createBeacon(data)
  template = '* [' + data[:author] + ' is LFM!](' + data[:url] + ') *Game: ' + data[:game] + '* *Time: ' + data[:time] + '* *Join Group>*'
  beacon   = {}

  beacon[:template]  = template
  beacon[:data]      = data

  @beacons.push(beacon)
end

def getBeacons()
  getCurrentBeacons();
  getNewBeacons()
  expireBeacons()
  saveBeacons()

  return @beacons
end

def saveBeacons()
  File.open(@beaconFilePath, 'w') { |f| YAML.dump(@beacons, f) }
end

def pastExpiration(creationTime)
  ((Time.now.utc - creationTime) / 60) > 120
end

def expireBeacons()
  @beacons.delete_if do |beacon|
    isExpired = pastExpiration(beacon[:data][:createdAt])

    if (isExpired)
      true
    end
  end
end

puts getBeacons()
