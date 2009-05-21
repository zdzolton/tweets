Cambric.configure do |config|
  config.design_doc_name = 'twitter-clone'
  config.environment = RAILS_ENV

  config.databases = {
    :users => {
      :development => 'http://127.0.0.1:5984/users-development',
      :test => 'http://127.0.0.1:5984/users-test'
    },
    :tweets => {
      :development => 'http://127.0.0.1:5984/tweets-development',
      :test => 'http://127.0.0.1:5984/tweets-test'
    }
  }
end
