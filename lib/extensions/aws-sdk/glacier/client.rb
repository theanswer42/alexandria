# Adds a high level api to the glacier client
# for now, only supports upload.
class AWS::Glacier::Client
  # part_size defines how big is the multi-part chunk size.
  #  nil - not multipart. only compute the root
  #  integer - size in MB
  # 
  # returns: 
  #  {:root => root_hash_value, :
  MAX_PART_SIZE = 4.gigabytes
  MAX_UPLOAD_SIZE = 8.megabytes
  def upload(options={})
    vault_name = options[:vault_name]
    path = options[:path]
    sha256sum = options[:checksum]
    description = options[:archive_description]
    part_size = options[:part_size] || MAX_PART_SIZE
    
    raise "File #{path} size is zero" if File.size(path)==0

    # for now, we'll only support simple uploads
    file_hashes = compute_hashes(path, part_size)
    
    if file_hashes[:linear_hash] != sha256sum
      raise "checksum mismatch on #{path}"
    end
    
    if file_hashes[:hashes_for_transport].length > 1
      return multipart_upload(options.merge(:file_hashes => file_hashes))
    else
      response = upload_archive(:account_id => '-', :vault_name => vault_name, :checksum => file_hashes[:tree_hash], :body => File.open(path, 'rb'), :archive_description => description)
      raise "No archive-id returned!  #{response.inspect}" unless response.archive_id
      raise "checksum sent back does not match!" unless response.checksum == file_hashes[:tree_hash]
      return response.archive_id
    end
  end
  
  private
  def multipart_upload(options={})
    vault_name = options[:vault_name]
    path = options[:path]
    description = options[:archive_description]
    file_hashes = options[:file_hashes]
    part_hashes = file_hashes[:hashes_for_transport]
    part_size = options[:part_size]
    
    response = initiate_multipart_upload(:account_id => '-', :vault_name => vault_name, :archive_description => description, :part_size => part_size)
    upload_id = response.upload_id
    
    file_parts_for_upload(path, part_size) do |index, io, range|
      tree_hash = part_hashes[index].to_s
      response = upload_multipart_part(:account_id => '-', :vault_name => vault_name, :upload_id => upload_id, :checksum => tree_hash, :range => range, :body => io)
      raise "Hash mismatch for part: #{index}" unless tree_hash == response.checksum
    end

    response = complete_multipart_upload(:account_id => '-', :vault_name => vault_name, :upload_id => upload_id, :archive_size => File.size(path), :checksum => file_hashes[:tree_hash])
    
    return response.archive_id
  end


  def file_parts_for_upload(path, part_size)
    file = File.open(path, 'rb')
    index = 0
    range_start = 0
    file_size = File.size(path)
    while(data = file.read(part_size))
      size = [part_size, data.size].min
      range_end = range_start + size - 1
      range = "bytes #{range_start}-#{range_end}/#{file_size-1}"
      yield(index, StringIO.new(data), range)
      range_start += part_size
      index += 1
    end
  end

  # computes a linear and tree hash for the given file
  # will only load one meg of the file at a time.
  def compute_hashes(path, part_size)
    raise "Cannot process empty file!" if File.size(path)==0
    file = File.open(path, 'rb')
    linear_hash = Digest::SHA256.new
    
    parts = []
    while(data = file.read(1.megabyte))
      linear_hash << data
      
      sha256sum = Digest::SHA256.new
      sha256sum << data
      parts << sha256sum
    end
    
    current_part_size = 1.megabyte
    parts_for_transport = []
    next_parts = []

    while true
      parts_for_transport = parts if current_part_size == part_size
      break if parts.length == 1

      index = 0
      while(!(pair = parts.slice(index,2)).blank?)
        if pair.size == 1
          next_parts << pair[0] 
          break
        end
        
        sha256sum = Digest::SHA256.new
        sha256sum << pair[0].digest
        sha256sum << pair[1].digest
        next_parts << sha256sum
        index += 2
      end
      
      parts = next_parts
      next_parts = []
      current_part_size = current_part_size * 2
    end
    {:linear_hash => linear_hash.to_s, :tree_hash => parts.first.to_s, :hashes_for_transport => parts_for_transport}
  end


end
