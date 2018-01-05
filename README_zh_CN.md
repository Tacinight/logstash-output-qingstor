# Logstash Output Plugin for QingStor

[![Build Status](https://travis-ci.org/yunify/logstash-output-qingstor.svg?branch=master)](https://travis-ci.org/yunify/logstash-output-qingstor)  [![Gem Version](https://badge.fury.io/rb/logstash-output-qingstor.svg)](https://badge.fury.io/rb/logstash-output-qingstor.svg) [![License](http://img.shields.io/badge/license-apache%20v2-blue.svg)](https://github.com/yunify/logstash-output-qingstor/blob/master/LICENSE) [![README English](https://img.shields.io/badge/README-English-blue.svg)](/README.md)

这是适配了 [QingStor](https://www.qingcloud.com/products/storage#qingstor) 的 Logstash output 插件。通过本插件可以将 Logstash 的结果导出到 QingStor 对象存储中。

> 已知在 Logstash 5.5.x 版本中会崩溃，请使用最新或者之前的 Logstash 版本。例如 6.0 以上版本或者 5.4 版本。

## 安装
目前插件已经提交至 [RubyGems](https://rubygems.org), 使用以下命令安装:

``` bash
$ bin/logstash-plugin install logstash-output-qingstor
```

如果你安装过一个早期的版本，可以通过以下的命令来更新插件：

``` bash
$ bin/logstash-plugin update logstash-output-qingstor
```

## 配置说明

#### 最小运行配置
编辑一个 `*.conf` 文件或者使用 `-e` 参数直接输入配置, 最小运行配置至少需要以下三项

``` bash
output {
    qingstor {
        access_key_id => 'your_access_key_id'           #required 
        secret_access_key => 'your_secret_access_key'   #required  
        bucket => 'bucket_name'                         #required 
        # region => "pek3a"                             #optional, default value "pek3a"                                
    }
}
```

#### 其他可选参数说明

``` bash
output {
    qingstor {
        ......
        # 前缀, 生成本地子目录, 并且添加到上传文件名的前半部分, 形成QingStor的目录.
        # 默认空, 
        prefix => 'aprefix'

        # 本地保存临时文件的目录. 
        # 默认: 系统临时文件目录下的logstash2qingstor文件夹, 例如linux下 "/tmp/logstash2qingstor"
        tmpdir => '/local/temporary/directory' 

        # 字符串数组, 添加到文件名中, 例如["a", "b", "c"], 文件名会形成如 xxx-a-b-c-xxx.xx 
        # 默认: 空
        tags => ["tag1", "tag2", "tag3"]

        # 上传文件的格式. 可选"gzip", 后缀为".gz".
        # 默认: "none", 后缀".log".
        encoding => "gzip"

        # 文件上传的策略.
        # 分别表示结合文件大小和时间的综合策略, 基于文件大小的策略, 以及基于时间的策略.
        # 基于文件大小的策略表示: 当文件大小满足预设值之后, 将文件上传.
        # 基于时间的策略表示: 每经过预设时间之后, 将文件上传.
        # 默认: "size_and_time". 可选枚举值["size_and_time", "size", "time"].
        rotation_strategy => "size_and_time"

        # 配合"size_and_time", "size"的可选配置型, 单位 megabyte(MB)
        # 默认: 5 (MB)
        size_file => 5

        # 配合"size_and_time", "time"的可选配置型, 单位 minute
        # 默认: 15 (minutes)
        time_file => 15 

        # 服务端文件加密, 支持AES256. 
        # 默认: "none". 可选枚举值: ["AES256", "none"]
        server_side_encryption_algorithm => "AES256"

        # 选用服务端文件加密时提供的秘钥, 秘钥要求 32 byte(256 bit)
        customer_key => "your_encryption_key"

        # 宕机恢复, 启动logstash时, 自动上传目录下的遗留文件
        # 默认: false
        restore => true                     
                                       
    }
}
```
## 特性 ([CHANGELOG](./CHANGELOG.md))
- 支持 gzip 压缩。
- 恢复上次宕机后未上传完成的文件。
- 服务端加密（AES256）。
- 重定向指自建的 QingStor 服务器。
- 分段上传支持最大 500GB 的文件。

## TODO
- 自定义上传文件的名称。
- 恢复意外终止的分段上传。

## Contributing
Please see [Contributing Guidelines](./CONTRIBUTING.md) of this project before submitting patches.

## LICENSE
The Apache License (Version 2.0, January 2004).