def fetch_event(settings, events_and_encoded)
  qs = LogStash::Outputs::Qingstor.new(settings)
  qs.register
  qs.multi_receive_encoded(events_and_encoded)
  qs.close
end

def qs_init_config(access_key_id = ENV['access_key_id'],
                   secret_access_key = ENV['secret_access_key'])
  QingStor::SDK::Config.init access_key_id, secret_access_key
end

def qs_init_bucket(bucket = ENV['bucket'], region = ENV['region'])
  config = qs_init_config
  properties = { 'bucket-name' => bucket, 'zone' => region }
  QingStor::SDK::Bucket.new(config, properties)
end

def delete_remote_file(key)
  bucket = qs_init_bucket
  bucket.delete_object key
end

def list_remote_file(bucket = ENV['bucket'], region = ENV['region'])
  bucket = qs_init_bucket(bucket, region)
  bucket.list_objects[:keys]
end

def delete_bucket(bucket)
  bucket = qs_init_bucket(bucket)
  bucket.delete
end

def clean_remote_files
  list_remote_file.each do |record|
    qs_init_bucket.delete_object record[:key]
  end
end
