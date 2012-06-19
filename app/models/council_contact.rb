class CouncilContact < ActiveRecord::Base
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validates_uniqueness_of :category, :scope => [:area_id, :deleted],
                                     :if => Proc.new{ |contact| ! contact.deleted? }

  has_paper_trail

  def name
    council_data = MySociety::MaPit.call('area', area_id)
    council_data['name']
  end

  def last_editor
    return nil if versions.empty?
    return versions.last.whodunnit
  end

  def deleted_or_organization_deleted?
    deleted?
  end

end
