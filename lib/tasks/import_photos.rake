namespace :photos do 
  task :import, [:path, :tags] => [:environment] do |t, args|
    puts args
    # path = args[0]
    # tags = args[1..-1]
    
    # Photo.import_directory(path, tags)
  end
end
