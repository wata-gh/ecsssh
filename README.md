# Hakossh

ssh to hako ECS instances.

## Installation

```ruby
gem install -s https://gemstash.ckpd.co/private hakossh
```

## Usage

```
$ hakossh -r apne1 -c hako-production -s store-tv-api
```

Help

```
Usage: hakossh [options]
    -h, --help                       Show help
    -r, --region VAL                 Specify AWS region for ECS
    -c, --cluster VAL                Specify cluster for ECS
    -s, --service VAL                Specify service for ECS
```		

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

