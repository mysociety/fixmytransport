class RawEmail < ActiveRecord::Base

  # store raw email as binary field without stripping
  def data=(email_data)
    write_attribute(:data_binary, email_data)
  end

  def data
    read_attribute(:data_binary)
  end
  
end
