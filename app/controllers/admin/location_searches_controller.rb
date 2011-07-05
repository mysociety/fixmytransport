class Admin::LocationSearchesController < Admin::AdminController
  
  def index
    @searches = WillPaginate::Collection.create((params[:page] or 1), 30) do |pager|
      searches = LocationSearch.find(:all, :order => 'created_at desc',
                                         :limit => pager.per_page,
                                         :offset => pager.offset)
      # inject the result array into the paginated collection:
      pager.replace(searches)

      unless pager.total_entries
        # the pager didn't manage to guess the total count, do it manually
        pager.total_entries = LocationSearch.count
      end
    end
  end
  
  def show
    @search = LocationSearch.find(params[:id])
  end
end
