config.fog_provider = 'fog-aws'

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'                        # required
  config.fog_credentials = {
    provider:              'AWS',                        # required
    aws_access_key_id:     'AKIAJKLKGAYCT7YE4YOA',                        # required
    aws_secret_access_key: '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',                        # required
    region:                'eu-east-2',                  # optional, defaults to 'us-east-1'
    host:                  's3-us-east-2.amazonaws.com',             # optional, defaults to nil
    endpoint:              'http://s3-us-east-2.amazonaws.com/skill-ex' # optional, defaults to nil
  }
  config.fog_directory  = 'skill-ex'                          # required
  config.fog_public     = false                                        # optional, defaults to true
  config.fog_attributes = { cache_control: "public, max-age=#{365.day.to_i}" } # optional, defaults to {}
