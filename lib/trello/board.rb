module Trello
  class Board < BasicData
    register_attributes :id, :name, :description, :closed, :url, :organization_id, :prefs, :pinned, :labelNames, :labels, :shortUrl, :memberships, :board_members,
      :readonly => [ :id, :url, :organization_id, :prefs ]
    validates_presence_of :id, :name
    validates_length_of   :name,        :in      => 1..16384
    validates_length_of   :description, :maximum => 16384

    include HasActions

    class << self
      # Finds a board.
      def find(id)
        client.find(:board, id)
      end

      def create(fields)
        client.create(:board,
          'name'   => fields[:name],
          'desc'   => fields[:description],
          'closed' => fields[:closed] || false)
      end

      def all
        client.get("/members/#{Member.find(:me).username}/boards").json_into(self)
      end
    end

    def save
      return update! if id

      fields = { :name => name }
      fields.merge!(:desc => description) if description
      fields.merge!(:idOrganization => organization_id) if organization_id

      client.post("/boards", fields).json_into(self)
    end

    def update!
      fail "Cannot save new instance." unless self.id

      @previously_changed = changes
      @changed_attributes.clear

      client.put("/boards/#{self.id}/", {
        :name        => attributes[:name],
        :description => attributes[:description],
        :closed      => attributes[:closed]
      }).json_into(self)
    end

    def update_fields(fields)
      attributes[:id]              = fields['id']              if fields['id']
      attributes[:name]            = fields['name']            if fields['name']
      attributes[:description]     = fields['desc']            if fields['desc']
      attributes[:closed]          = fields['closed']          if fields.has_key?('closed')
      attributes[:pinned]          = fields['pinned']          if fields.has_key?('pinned')
      attributes[:url]             = fields['url']             if fields['url']
      attributes[:shortUrl]        = fields['shortUrl']        if fields['shortUrl']
      attributes[:organization_id] = fields['idOrganization']  if fields['idOrganization']
      attributes[:labels]          = fields['labels']          if fields['labels']
      attributes[:labelNames]      = fields['labelNames'] || {}
      attributes[:prefs]           = fields['prefs'] || {}
      attributes[:memberships]     = fields['memberships']     if fields['memberships']

      attributes[:board_members]         = fields['members']         if fields['members']

      # merge memberships into member data
      unless attributes[:board_members].nil?
        attributes[:board_members].each do |member|
          # find corresponding membership
          member['memberType'] = attributes[:memberships].select { |m| (m["idMember"] == member['id']) }[0]['memberType']
        end
      end

      self
    end

    def closed?
      attributes[:closed]
    end

    def has_lists?
      lists.size > 0
    end

    def find_card(card_id)
      client.get("/boards/#{self.id}/cards/#{card_id}").json_into(Card)
    end

    # Return all the cards on this board.
    #
    # This method, when called, can take a hash table with a filter key containing any
    # of the following values:
    #    :filter => [ :none, :open, :closed, :all ] # default :open
    many :cards, :filter => :open

    # Returns all the lists on this board.
    #
    # This method, when called, can take a hash table with a filter key containing any
    # of the following values:
    #    :filter => [ :none, :open, :closed, :all ] # default :open
    many :lists, :filter => :open

    # Returns an array of members who are associated with this board.
    #
    # This method, when called, can take a hash table with a filter key containing any
    # of the following values:
    #    :filter => [ :none, :normal, :owners, :all ] # default :all
    many :members, :filter => :all, :fields => :all

    # Returns a reference to the organization this board belongs to.
    one :organization, :path => :organizations, :using => :organization_id

    # :nodoc:
    def request_prefix
      "/boards/#{id}"
    end
  end
end
