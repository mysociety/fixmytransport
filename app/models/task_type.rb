class TaskType < ActiveResource::Base
  self.site = MySociety::Config.get("FOSBURY_URL", '')
  self.format = :json
end