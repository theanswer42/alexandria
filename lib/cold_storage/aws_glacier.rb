# This abstracts cold storage functionality for Document
module ColdStorage
  module AwsGlacier
    module ClassMethods
      def glacier_client
        glacier = AWS::Glacier.new
        glacier.client
      end

      def batch_archive!(batch_size=1000)
        documents = Document.where(:archived_at => nil).limit(batch_size).all
        Rails.logger.info "ColdStorage::AwsGlacier - Starting batch archive for #{documents.size} documents."
        Rails.logger.info "ColdStorage::AwsGlacier - Creating necessary vaults."
        self.create_vaults
        
        Rails.logger.info "ColdStorage::AwsGlacier - Starting uploads."
        documents.each do |document|
          document.archive!(:skip_create_vault => true)
        end
        
        Rails.logger.info "ColdStorage::AwsGlacier - Done."
      end
      
      def create_vaults
        client = self.glacier_client
        vaults = client.list_vaults(:account_id => '-')
        vault_list = vaults[:vault_list]
        vaults_hash = vault_list.each_with_object({}) {|vault, hash| hash[vault[:vault_name]] = vault }
        
        self.connection.execute("select distinct date_format(timestamp, '%Y_%m') 'month' from documents").each do |row|
          vault_name = "#{Rails.env.downcase}_#{row[0]}"
          if !vaults_hash[vault_name]
            Rails.logger.info "Creating vault #{vault_name}"
            client.create_vault(:account_id => '-', :vault_name => vault_name)
          end
        end
      end
      
    end
    
    module InstanceMethods
      def archive!(options={})
        return if self.new_record?
        
        client = self.class.glacier_client

        unless options[:skip_create_vault]
          client.create_vault(:account_id => '-', :vault_name => vault_name)
        end
        begin
          bm = Benchmark.measure do
            archive_id = client.upload(:vault_name => vault_name, :path => library_filename, :checksum => checksum)
            update_attributes!(:archive_id => archive_id, :archived_at => Time.now)
          end
          Rails.logger.info "document: #{self.filename} archived in #{bm.real} seconds."
        rescue Exception => e
          Rails.logger.error "Exception while uploading archive: #{e.inspect}"
        end
      end

      private
      def vault_name
        "#{Rails.env.downcase}_#{timestamp.strftime('%Y_%m')}"
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do 
  extend ColdStorage::AwsGlacier::ClassMethods
  include ColdStorage::AwsGlacier::InstanceMethods
end
