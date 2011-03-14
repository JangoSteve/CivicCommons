class ConversationsController < ApplicationController
  before_filter :require_user, :only=>[:new, :create, :new_node_contribution, :preview_node_contribution, :confirm_node_contribution]

  # GET /conversations
  def index
    @active = Conversation.includes(:participants).latest_updated.limit(3)
    @popular = Conversation.includes(:participants).get_top_visited(3)
    @recent = Conversation.includes(:participants).latest_created.limit(3)

    @regions = Region.all
    @recent_items = TopItem.newest_items(3).for(:conversation).collect(&:item)
    render :index
  end

  def filter
    @filter = params[:filter]
    @conversations = Conversation.includes(:participants).filtered(@filter).paginate(:page => params[:page], :per_page => 12)

    @regions = Region.all
    @recent_items = TopItem.newest_items(3).for(:conversation).collect(&:item)
    render :filter
  end

  # GET /conversations/1
  def show
    @conversation = Conversation.includes(:issues).find(params[:id])
    @conversation.visit!((current_person.nil? ? nil : current_person.id))
    @contributions = Contribution.for_conversation(@conversation)
    @top_level_contributions = @contributions.select{ |c| c.is_a?(TopLevelContribution) }
    # grab all direct contributions to conversation that aren't TLC
    @conversation_contributions = @contributions.select{ |c| !c.is_a?(TopLevelContribution) && c.parent_id.nil? }

    @top_level_contribution = Contribution.new # for conversation comment form
    @tlc_participants = @top_level_contributions.collect{ |tlc| tlc.owner }

    @latest_contribution = @conversation.confirmed_contributions.most_recent.first

    @recent_items = TopItem.newest_items(5).for(:conversation => @conversation.id).collect(&:item)

    render :show
  end

  def node_conversation
    @contribution = Contribution.find(params[:id])
    @contributions = @contribution.descendants.confirmed.includes(:person)
    @contribution.visit!((current_person.nil? ? nil : current_person.id))

    respond_to do |format|
      format.js { render :partial => "conversations/node_conversation", :layout => false}
      format.html { render :partial => "conversations/node_conversation", :layout => false}
    end
  end

  def node_permalink
    contribution = Contribution.find(params[:id])
    @contributions = contribution.self_and_ancestors
    @top_level_contribution = @contributions.root
    contribution.visit!((current_person.nil? ? nil : current_person.id))

    respond_to do |format|
      format.js
    end
  end

  def edit_node_contribution
    @contribution = Contribution.find(params[:contribution_id])
    respond_to do |format|
      format.js{ render(:partial => 'conversations/new_contribution_form', :locals => {:div_id => params[:div_id], :type => @contribution.type.underscore.to_sym}, :layout => false) }
    end
  end

  def update_node_contribution
    @contribution = Contribution.find(params[:contribution][:id])
    respond_to do |format|
      if @contribution.update_attributes_by_user(params[:contribution], current_person)
        format.js{ render(:partial => "conversations/contributions/threaded_contribution_template", :locals => {:contribution => @contribution, :div_id => params[:div_id]}, :layout => false, :status => :ok) }
      else
        format.js   { render :json => @contribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new_node_contribution
    @contribution = Contribution.find_or_new_unconfirmed(params, current_person)
    respond_to do |format|
      format.js { render(:partial => "conversations/tabbed_post_box", :locals => {:div_id => params[:div_id], :layout => false}) }
      format.html { render(:partial => "conversations/tabbed_post_box", :locals => {:div_id => params[:div_id], :layout => false}) }
    end
  end

  def preview_node_contribution
    @contribution = Contribution.update_or_create_node_level_contribution(params[:contribution], current_person)
    respond_to do |format|
      if @contribution.valid?
        format.js { render(:partial => "conversations/new_contribution_preview", :locals => {:div_id => params[:div_id], :layout => false}) }
        format.html { render(:partial => "conversations/new_contribution_preview", :locals => {:div_id => params[:div_id], :layout => 'application'}) }
      else
        format.js   { render :json => @contribution.errors, :status => :unprocessable_entity }
        format.html { render :text => @contribution.errors.full_messages, :status => :unprocessable_entity }
      end
    end
  end

  #TODO: consider moving this to its own controller?
  def confirm_node_contribution
    @contribution = Contribution.unconfirmed.find_by_id_and_owner(params[:contribution][:id], current_person.id)

    respond_to do |format|
      if @contribution.confirm!
        Subscription.create_unless_exists(current_person, @contribution.item)
        format.js   { render :partial => "conversations/contributions/threaded_contribution_template", :locals => {:contribution => @contribution}, :status => (params[:preview] ? :accepted : :created) }
        format.html   { render :partial => "conversations/contributions/threaded_contribution_template", :locals => {:contribution => @contribution}, :status => (params[:preview] ? :accepted : :created) }
      else
        format.js   { render :json => @contribution.errors, :status => :unprocessable_entity }
        format.html { render :text => @contribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /conversations/new
  def new
    return redirect_to :conversation_responsibilities unless params[:accept]
    @conversation = Conversation.new
    @contributions = [Contribution.new]

    render :new
  end

  # GET /conversations/1/edit
  # NOT IMPLEMENTED YET, I.E. NOT ROUTEABLE
  def edit
    @conversation = Conversation.find(params[:id])
  end

  # POST /conversations
  def create
    @conversation = Conversation.new_user_generated_conversation(params[:conversation], current_person)
    @conversation.started_at = Time.now
    # Load @contributions to populate re-rendered :new form if save is unsuccessful
    @contributions = @conversation.contributions | @conversation.rejected_contributions

    respond_to do |format|
      if @conversation.save
        format.html { redirect_to(new_invite_path(:source_type => :conversations, :source_id => @conversation.id, :conversation_created => true), :notice => 'Your conversation has been created!') }
      else
        format.html { render :new, :status => :unprocessable_entity  }
      end
    end
  end

  # PUT /conversations/1
  # NOT IMPLEMENTED YET, I.E. NOT ROUTEABLE
  def update
    @conversation = Conversation.find(params[:id])

    if @conversation.update_attributes(params[:conversation])
      redirect_to(@conversation, :notice => 'Conversation was successfully updated.')
    else
      render :action => "edit", :status => :unprocessable_entity
    end
  end

  def rate_contribution
    @contribution = Contribution.find(params[:contribution][:id])
    rating = params[:contribution][:rating]

    respond_to do |format|
      if @contribution.rate!(rating.to_i, current_person)
        format.js { render(:partial => 'conversations/contributions/rating', :locals => {:contribution => @contribution}, :layout => false, :status => :created) }
      end
        format.js { render :json => @contribution.errors[:rating].first, :status => :unprocessable_entity }
    end
  end

  # DELETE /conversations/1
  # NOT IMPLEMENTED YET, I.E. NOT ROUTEABLE
  def destroy
    @conversation = Conversation.find(params[:id])
    @conversation.destroy

    redirect_to(conversations_url)
  end

  # Kludge to convert US date-time (mm/dd/yyyy hh:mm am) to an
  # ISO-like date-time (yyyy-mm-ddThh:mm:ss).
  # There is probably a better way to do this. Please refactor.
  private
  def convert_us_date_to_iso(input)
    hour = input[11,2].to_i
    if (hour == 12)
      hour = 0
    end
    if (input[17,2] == "pm")
      hour += 12
    end
    hour = sprintf("%02d",hour)
    input[6,4]+"-"+input[0,2]+"-"+input[3,2]+"T"+hour+":"+input[14,2]+":00"
  end

end
