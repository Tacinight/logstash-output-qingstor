def qs_init_config(access_key_id = ENV['access_key_id'],
                   secret_access_key = ENV['secret_access_key'])
  return QingStor::SDK::Config.init access_key_id, secret_access_key
end 

def qs_init_bucket(bucket = ENV['bucket'], region = ENV['region'])
  config = qs_init_config
  properties = {'bucket-name' => bucket, 'zone' => region }
  return QingStor::SDK::Bucket.new(config, properties)
end 

def delete_remote_file(key)
  bucket = qs_init_bucket
  bucket.delete_object key
end

def list_remote_file(bucket = ENV['bucket'], region = ENV['region'])
  bucket = qs_init_bucket(bucket, region)
  return bucket.list_objects[:keys]
end

def delete_bucket(bucket)
  bucket = qs_init_bucket(bucket)
  bucket.delete
end 