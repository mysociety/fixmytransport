class Task < ActiveResource::Base
  self.format = :json
  self.site = MySociety::Config.get("FOSBURY_URL", '')
  self.user = MySociety::Config.get("FOSBURY_API_APPLICATION_NAME", '')
  self.password = MySociety::Config.get("FOSBURY_API_KEY", '')
  self.timeout = 5
end