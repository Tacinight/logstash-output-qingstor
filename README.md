# Logstash Output Plugin for QingStor 
[![Build Status](https://travis-ci.org/yunify/logstash-output-qingstor.svg?branch=master)](https://travis-ci.org/yunify/logstash-output-qingstor)  [![Gem Version](https://badge.fury.io/rb/logstash-output-qingstor.svg)](https://badge.fury.io/rb/logstash-output-qingstor.svg) [![License](http://img.shields.io/badge/license-apache%20v2-blue.svg)](https://github.com/yunify/logstash-output-qingstor/blob/master/LICENSE) [![README Chinese](https://img.shields.io/badge/README-%E4%B8%AD%E6%96%87-blue.svg)](/README_zh_CN.md)

This is a Logstash output plugin, it collects the outputs from logstash, and store them in [QingStor](https://www.qingcloud.com/products/storage#qingstor).

> Incompatible with Logstash version 5.5.x. Please use the least or previous releases to avoid crashing down errors, such as 6.0.0+ or 5.4.x.

## How to use
This plugin has submitted to [rubygems.org](rubygems.org). Use the following command to install:

``` bash
$ bin/logstash-plugin install logstash-output-qingstor
```

If you have installed a previous release, please use the folliwing command to update:

```bash
$ bin/logstash-plugin update logstash-output-qingstor
```

#### Run in minimal Configuration Items
Edit a conf file, fill `output` field with qingstor configurations.
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

> More configuration details please refer to [common options](/docs/index.asciidoc).

## Features ([CHANGELOG](./CHANGELOG.md))
- Support gzip compress.
- Restore uncomplete files.
- Server size encrption.
- Redirect QingStor hosts.
- Multipart uploading supports 500GB file.

## TODO
- Custom stored file name.
- Restore uncomplete multipart uploading

## Contributing
Please see [Contributing Guidelines](./CONTRIBUTING.md) of this project before submitting patches.

## LICENSE
The Apache License (Version 2.0, January 2004).