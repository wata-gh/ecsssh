require 'optparse'
require 'aws-sdk'
require 'peco_selector'

module Ecsssh
  class CLI
    SHORT_REGIONS = {
      'apne1' => 'ap-northeast-1',
      'apse1' => 'ap-southeast-1',
      'apse2' => 'ap-southeast-2',
      'euc1' => 'eu-central-1',
      'sae1' => 'sa-east-1',
      'use1' => 'us-east-1',
      'usw1' => 'us-west-1',
      'usw2' => 'us-west-2',
    }

    def self.start(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv.dup
      parser.order!(@argv)
    end

    def run
      if @help
        puts parser.help
        return
      end

      cis = instances(services)
      if cis.empty?
        puts "no container instance found."
        puts "region: #{@region}"
        puts "cluster: #{@cluster}"
        puts "service: #{@service}"
        return
      end

      if cis.length > 1
        cis = PecoSelector.select_from(peco_format(cis, %w/service name vpc fqdn/))
      end

      ssh_bin = cis.length == 1 ? 'ssh' : ENV["HAKOSSH_CSSH"] || 'cssh'
      cmd = [ssh_bin]
      if ssh_options = @ssh_options
        cmd += ssh_options.shellsplit
      end
      cmd += cis.map { |ci| ci['fqdn'] }
      puts cmd.shelljoin

      exec(*cmd)
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.version = VERSION
        opts.on('-h', '--help', 'Show help') { @help = true }
        opts.on('-r VAL', '--region', 'Specify AWS region for ECS') { |v| @region = v }
        opts.on('-c VAL', '--cluster', 'Specify cluster for ECS') { |v| @cluster = v }
        opts.on('-s VAL', '--service', 'Specify service for ECS') { |v| @service = v }
      end
    end

    private

    def vpc_name_from_region(region)
      case region
      when 'ap-northeast-1'
        'apne1'
      when 'us-east-1'
        'use1'
      else
        raise "Unknown region: #{region}"
      end
    end

    def peco_format(list, keys)
      cnt_hash = Hash.new(0)
      list.each do |h|
        keys.each do |k|
         cnt_hash[k] = h[k].length if h[k].length > cnt_hash[k]
        end
      end

      list.map do |h|
        keys.map do |k|
          h[k].ljust(cnt_hash[k])
        end.join(' ')
      end.zip(list)
    end

    def region
      if @region
        return SHORT_REGIONS.fetch(@region, @region)
      end
      return @region = ENV['AWS_REGION'] if ENV['AWS_REGION']
      return @region = ENV['AWS_DEFAULT_REGION'] if ENV['AWS_DEFAULT_REGION']

      @region = PecoSelector.select_from(SHORT_REGIONS.values).first
    end

    def cluster
      return @cluster if @cluster

      next_token = nil
      clusters = []

      loop do
        resp = ecs.list_clusters
        clusters.push(*resp.cluster_arns)
        next_token = resp.next_token
        break unless next_token
      end
      @cluster = PecoSelector.select_from(clusters).first
    end

    def services
      service_arns = []
      next_token = nil
      loop do
        ecs.list_services(cluster: cluster, next_token: next_token).each do |page|
          if @service
            page.service_arns.each do |service_arn|
              if service_arn =~ %r{service/#{@service}[-0-9]*\z}
                service_arns.push(service_arn)
              end
            end
          else
            service_arns.push(page.service_arns)
          end
          next_token = page.next_token
        end
        break unless next_token
      end
      service_arns = service_arns.flatten
      if service_arns.empty?
        raise "no service found. region: #{@region}, cluster: #{@cluster}, service: #{@service}"
      end

      if service_arns.length == 1
        return service_arns
      end
      PecoSelector.select_from(service_arns.flatten)
    end

    def instances(service_arns)
      container_instances = []
      next_token = nil
      service_arns.each do |service_arn|
        loop do
          ecs.list_tasks(cluster: cluster, service_name: service_arn, next_token: next_token).each do |page|
            break if page.task_arns.empty?
            arns = ecs.describe_tasks(cluster: cluster, tasks: page.task_arns).tasks.map(&:container_instance_arn)
            ecs.describe_container_instances(cluster: cluster, container_instances: arns).container_instances.each do |ci|
              if cluster.start_with?('arn:aws:ecs:')
                cluster_name = cluster.slice(%r{:cluster/(.+)\z}, 1)
              else
                cluster_name = cluster
              end
              name = "ecs-#{cluster_name}-#{ci.ec2_instance_id}"
              vpc = vpc_name_from_region(region)
              fqdn = "#{name}.#{vpc}.aws.ckpd.co"
              id = ci.container_instance_arn.slice(%r{:container-instance/(.+)\z}, 1)
              container_instances << {
                'id' => id,
                'fqdn' => fqdn,
                'vpc' => vpc,
                'name' => name,
                'service' => service_arn.slice(%r{:service/(.+)\z}, 1),
              }
            end
            next_token = page.next_token
          end
          break unless next_token
        end
      end
      container_instances
    end

    def ecs
      @ecs ||= Aws::ECS::Client.new(
        region: region
      )
    end
  end
end
