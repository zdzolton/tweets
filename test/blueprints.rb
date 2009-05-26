require 'populator'
require 'faker'

Sham.login { "#{Faker::Name.first_name}_#{Faker::Name.last_name}".gsub(/'/, '')[0,15].downcase }
Sham.sentence { Faker::Lorem.sentence }

class CouchRestExt::Model
  
  class << self
    def make attributes={}
      new(@_blueprint_block.call.merge(attributes)).tap do |obj|
        yield obj if block_given?
        obj.save
      end
    end
  
    def blueprint &block
      @_blueprint_block = block
    end
  end

end

Follow.blueprint do
  follower_id { User.make.id }
  following_id { User.make.id }
end

Tweet.blueprint do
  user
  body { Sham.sentence }
end

User.blueprint do
  login { Sham.login }
end

FeedItem.blueprint do
  tweet = Tweet.make
  user
  tweet_id { tweet.id }
  tweet_user_id { tweet.user_id }
  tweet_created_at { tweet.created_at }
end
