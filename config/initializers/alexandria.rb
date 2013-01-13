config = YAML.load_file(Rails.root.join('config', 'alexandria.yml'))
if Rails.env.test?
  BASE_PATH = Rails.root.join('tmp', 'documents').to_s
else
  BASE_PATH = config[Rails.env]['base_path']
end
