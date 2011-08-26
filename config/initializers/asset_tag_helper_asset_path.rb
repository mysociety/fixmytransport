# A monkey-patch to AssetTagHelper that prepends a directory with the rails asset it 
# to asset paths as well as using an asset query string. CDNs may ignore the querystring
# so this is belt-and-braces cache busting. Requires a webserver-level rewrite rule
# to strip the /rel-[asset-id]/ directory

module ActionView
  module Helpers #:nodoc:
    module AssetTagHelper
    
      private
        
        if MySociety::Config.getbool("USE_VERSIONED_ASSET_PATHS", false)
          def rewrite_asset_path(source)
            asset_id = rails_asset_id(source)
            if asset_id.blank?
              source
            else
              "/rel-#{asset_id}" + source + "?#{asset_id}"
            end
          end
        
          def asset_file_path(path)
            path = path.gsub(/^\/rel-\d+/, '')
            file_path = File.join(ASSETS_DIR, path.split('?').first)
          end
        end
    end
  end
end
