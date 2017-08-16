# Logstash Output Plugin for QingStor

[English](/README.md) | 中文

作为一个 Logstash 的 Output 插件, 它可以将 Logstash 输出的结果打包上传至 QingStor 对象存储中.  
详细功能参考下面配置说明.  

目前插件已经提交至 [RubyGems](https://rubygems.org), 使用以下命令安装:

``` bash
$ bin/logstash-plugin install logstash-output-qingstor
```

 手动安装本地代码, 安装方法参考下文.

## 1. 配置说明

#### 1.1 最小运行配置
- 使用 `-f` 接受一个 `*.conf` 文件或者使用 `-e` 参数直接输入配置, 最小运行配置至少需要以下三项
- 
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

#### 1.2 其他可选参数说明

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

        # 配合"size_and_time", "size"的可选配置型, 单位byte
        # 默认: 1024*1024*5 (byte) = 5 (MB)
        size_file => 1024*1024*5

        # 配合"size_and_time", "time"的可选配置型, 单位minute
        # 默认: 15 (minutes)
        time_file => 15 

        # 服务端文件加密, 支持AES256. 
        # 默认: "none". 可选枚举值: ["AES256", "none"]
        server_side_encryption_algorithm => "AES256"

        # 选用服务端文件加密时提供的秘钥, 秘钥要求32位/256bit
        customer_key => "your_encryption_key"

        # 宕机恢复, 启动logstash时, 自动上传目录下的遗留文件
        # 默认: false
        restore => true                     
                                       
    }
}
```

## 2. 安装插件

#### 2.1 直接运行本地的插件

- 编辑 Logstash 目录下的 Gemfile, 添加插件的路径, 例如

``` ruby
$ gem "logstash-output-qingstor", :path => "/your/local/logstash-output-qingstor"
```

- 安装插件

``` bash
$ bin/logstash-plugin install --no-verify
```

- 使用插件运行
- 
``` bash
$ bin/logstash -e "output { \
      qingstor { \
          access_key_id => 'your_access_key_id' \
          secret_access_key => 'your_secret_access_key' \
          bucket => 'bucket_name' \
      } \
  }"
```

此时你对插件所做的任意的代码上的修改都会直接生效.

#### 2.2 安装一个本地插件然后运行

这一步你需要生成一个插件的 Gem 包, 然后通过 Logstash 来安装到 Logstash 的插件目录下
- 在项目目录下生成 Gem

``` bash
$ gem build logstash-output-qingstor.gemspec
```

- 在 Logstash 的目录下使用 `logstash-plugin` 安装

``` bash
$ bin/logstash-plugin install /your/local/plugin/logstash-output-qingstor.gem
```

- 安装完毕之后, 就可以使用 Logstash 运行开始测试了.
