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
    parts_for_transport = []
    # We'll skip any file bigger than 8 megs until we support multipart uploads
    raise "File #{path} too big (for now)" if File.size(path) >= MAX_UPLOAD_SIZE

    # for now, we'll only support simple uploads
    file_hashes = compute_hashes(path)
    
    # {:linear_hash => linear_hash, :tree_hash => parts.first, :hashes_for_transport => parts_for_transport}
    if file_hashes[:linear_hash] != sha256sum
      raise "checksum mismatch on #{path}"
    end
    
    if parts_for_transport.length > 1
      # this will do the multipart upload
      raise "File #{path} too big (for now)"
    else
      response = upload_archive(:account_id => '-', :vault_name => vault_name, :checksum => file_hashes[:tree_hash], :body => File.open(path, 'rb'))
      raise "No archive-id returned!" unless response.archive_id
      raise "checksum sent back does not match!" unless response.checksum == file_hashes[:tree_hash]
      
      return response.archive_id
    end
    
  end
  
  private
  # computes a linear and tree hash for the given file
  # will only load one meg of the file at a time.
  def compute_hashes(path, part_size = MAX_PART_SIZE)
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
          next
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
