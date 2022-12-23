# frozen_string_literal: true

require 'pathname'
require 'forwardable'
require 'mime/types'
require 'digest/md5'

class S3Website
  class Item
    attr_reader :key, :hash, :mime_type, :max_age

    def initialize(key, hash, mime_type, max_age)
      @key = key
      @hash = hash
      @mime_type = mime_type
      @max_age = max_age
    end

    def ==(other)
      other.key == key &&
        other.hash == hash &&
        other.mime_type == mime_type &&
        other.max_age == max_age
    end
  end

  class ItemSet
    include Enumerable
    extend Forwardable

    attr_reader :items

    def_delegators :@items, :each, :<<

    def initialize(items)
      @items = items
    end

    def missing(other)
      self_keys = Set.new(items.collect(&:key))
      other_keys = Set.new(other.items.collect(&:key))

      difference = self_keys.difference(other_keys)

      ItemSet.new(items.select { |i| difference.include?(i.key) })
    end

    def different(other)
      intersection = key_set(self).intersection(key_set(other))
      modified = intersection.reject do |key|
        find_item_in(self, key) == find_item_in(other, key)
      end

      ItemSet.new(items.select { |i| modified.include?(i.key) })
    end

    private

    def key_set(item_set)
      Set.new(item_set.items.collect(&:key))
    end

    def find_item_in(item_set, key)
      item_set.items.find { |i| i.key == key }
    end
  end

  class DirectorySource
    def initialize(path)
      @source = Pathname.new(path)
    end

    def traverse(&block)
      @source.find
             .select(&:file?)
             .collect { |e| block.call(e.to_s) }
    end
  end

  class BucketDestination
    def initialize(bucket, region)
      @destination = Aws::S3::Resource.new(region:).bucket(bucket)
    end

    def traverse(&block)
      @destination.objects
                  .collect { |o| block.call(o) }
    end
  end

  def initialize(configuration)
    @configuration = configuration
    @bucket = configuration[:bucket]
    @region = configuration[:region]
    @s3 = Aws::S3::Resource.new(region: configuration[:region])
  end

  def publish_from(directory)
    source_item_set = directory_item_set_for(directory)
    destination_item_set = bucket_item_set_for(@bucket, @region)

    added = source_item_set.missing(destination_item_set)
    updated = source_item_set.different(destination_item_set)
    removed = destination_item_set.missing(source_item_set)

    bucket = @s3.bucket(@configuration[:bucket])
    add_files(bucket, directory, added)
    update_files(bucket, directory, updated)
    remove_files(bucket, removed)
  end

  private

  def add_file(bucket, directory, file)
    bucket.put_object(
      key: file.key,
      body: File.read(File.join(directory, file.key)),
      content_type: file.mime_type,
      cache_control: "max-age=#{file.max_age}"
    )
  end

  def add_files(bucket, directory, files)
    files.each { |file| add_file(bucket, directory, file) }
  end

  def update_file(bucket, directory, entry)
    bucket.put_object(
      key: entry.key,
      body: File.read(File.join(directory, entry.key)),
      content_type: entry.mime_type,
      cache_control: "max-age=#{entry.max_age}"
    )
    # invalidate
  end

  def update_files(bucket, directory, files)
    files.each { |file| update_file(bucket, directory, file) }
  end

  def remove_file(bucket, entry)
    bucket.delete_objects(
      delete: {
        objects: [{ key: entry.key }]
      }
    )
    # invalidate
  end

  def remove_files(bucket, files)
    files.each { |file| remove_file(bucket, file) }
  end

  def directory_item_set_for(directory)
    items = DirectorySource.new(directory)
                           .traverse do |f|
      Item.new(
        Pathname.new(f).relative_path_from(Pathname.new(directory)).to_s,
        md5_hash_for(f),
        mime_type_for(f),
        max_age_for(f)
      )
    end

    ItemSet.new(items)
  end

  def bucket_item_set_for(bucket, region)
    items = BucketDestination.new(bucket, region)
                             .traverse do |o|
      Item.new(
        o.key,
        o.etag.gsub('"', ''),
        o.get.content_type,
        o.get.cache_control && o.get.cache_control.gsub('max-age=', '').to_i
      )
    end

    ItemSet.new(items)
  end

  def md5_hash_for(file)
    Digest::MD5.file(file).to_s
  end

  def mime_type_for(file)
    MIME::Types.type_for(file).first.simplified
  end

  def max_age_for(file)
    @configuration[:max_ages][mime_type_for(file).to_sym]
  end
end
