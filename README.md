# Logstash Output Plugin for QingStor 

English | [中文](/README_zh_CN.md)

As an output plugin, it can collect the outputs from logstash, and store them in [QingStor](https://www.qingcloud.com/products/storage#qingstor), which is a remarkable object storage service provided by [QingCloud](https://www.qingcloud.com/).

> Current logstash release(5.5.x) has compatibility issues with this plugin, some unknown errors may cause the uploading failing. Please use the previous releases of logstash, such as version 5.4.3.

For now, We've submitted this plugin to rubygems.org. Use the following command to install.

``` bash
$ bin/logstash-plugin install logstash-output-qingstor
```

If you have installed a previous release, please use the folliwing command to update.

```bash
$ bin/logstash-plugin update logstash-output-qingstor
```

If want to install the local code, please refer to the following guide to install it manually.

## 1. Configuration Guide

#### 1.1 Run in minimal Configuration Items

```sh
output {
    qingstor {
        access_key_id => 'your_access_key_id'           #required 
        secret_access_key => 'your_secret_access_key'   #required  
        bucket => 'bucket_name'                         #required 
        # region => "pek3a"                             #optional, default value "pek3a"                                
    }
}

```

More configuration details please refer to [common options](/docs/index.asciidoc).

## 2. Running your unpublished Plugin in Logstash

#### 2.1 Run in a local Logstash clone

- Edit Logstash `Gemfile` and add the local plugin path, for example:
- 
``` ruby
$ gem "logstash-output-qingstor", :path => "/your/local/logstash-output-qingstor"
```

- Install plugin
- 
``` bash
$ bin/logstash-plugin install --no-verify
```
- Run Logstash with your plugin

```bash
$ bin/logstash -e "output { \
      qingstor { \
          access_key_id => 'your_access_key_id' \
          secret_access_key => 'your_secret_access_key' \
          bucket => 'bucket_name' \
      } \
  }"
```

At this point any modifications to the plugin code will be applied to this local Logstash setup. After modifying the plugin, simply rerun Logstash.

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem

``` bash
$ gem build logstash-output-qingstor.gemspec
```
- Install the plugin from the Logstash home

``` bash
$ bin/logstash-plugin install /your/local/plugin/logstash-output-qingstor.gem
```

- Start Logstash and proceed to test the plugin

## Contributing
Please see [Contributing Guidelines](./CONTRIBUTING.md) of this project before submitting patches.

## LICENSE
The Apache License (Version 2.0, January 2004).