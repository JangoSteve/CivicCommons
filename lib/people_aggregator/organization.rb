class PeopleAggregator::Organization < PeopleAggregator::Account
  attr_allowable :login, :email, :id, :url,
                 :name, :profile, :firstName,
                 :lastName, :login, :password,
                 :profilePictureURL, :groupName,
                 :image, :profileAvatarURL, :profileAvatarSmallURL,
                 :profilePictureWidth, :profilePictureHeight,
                 :profileAvatarWidth, :profileAvatarHeight,
                 :profileAvatarSmallWidth, :profileAvatarSmallHeight

  def save

    @attrs.merge!(adminPassword: Civiccommons::PeopleAggregator.admin_password,
                  groupType: "store",
                  category: "cat:1",
                  tags: "tmp",
                  description: "tmp",
                  accessType: "public",
                  registrationType: "open",
                  image: "",
                  moderationType: "direct",
                  profilePictureWidth: 100,
                  profilePictureHeight: 100,
                  profileAvatarWidth: 70,
                  profileAvatarHeight: 70,
                  profileAvatarSmallWidth: 40,
                  profileAvatarSmallHeight: 40)

    self.class.log_people_aggregator_request('/civiccommons/newOrg', body: @attrs)

    r = self.class.post('/civiccommons/newOrg', body: @attrs)

    self.class.log_people_aggregator_response r

    case r.code
    when 412
      self.class.handle_412(r)
    when 409
      login_name = r.parsed_response['msg'][/Login name (.*) is already taken/, 1]
      raise StandardError, 'The user with login "%s" already exists.' % login_name
    end

    self.id = r.parsed_response["id"]

    r.code == 200
  end


  def self.find_by_admin_email(email)
    r = get('/get...?email=%s' % email)

    log_people_aggregator_response r

    case r.code
    when 404
      return nil
    end

    attrs = r.parsed_response

    cleanup_attrs!(attrs)

    self.new(attrs)

  end


  def self.create(attrs)
    self.new(attrs).tap { |p| p.save }
  end


end
