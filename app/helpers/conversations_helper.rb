module ConversationsHelper
  def format_rating(contribution)
    return "" unless contribution.total_rating
    out = contribution.total_rating > 0 ? "+" : ""
    out += contribution.total_rating.to_s
  end
  
  def format_user_rating(value)
    return case value
    when 1
      "You found this productive"
    else
      "You found this unproductive"
    end
  end

  def format_time(t)
     return "no particular time" if t.nil?
     return t.localtime.strftime("%c")
  end
  
  def format_time_only(t)
    return t.localtime.strftime("%l:%M %p") unless t.nil?
  end

  def format_date(t)
    t.localtime.strftime("%b %e, %G") unless t.blank?
  end
  
  def contribution_action_past_tense(contribution_type)
    case contribution_type
    when "Answer"
      "answered a question"
    when "AttachedFile"
      "shared a file"
    when "Comment"
      "commented"
    when "EmbeddedSnippet"
      "shared a video"
    when "Link"
      "shared a link"
    when "Question"
      "asked a question"
    when "SuggestedAction"
      "suggested an action"
    else
      "responded"
    end
  end
  
  def contribution_form_placeholder_text_for(type)
    case type
    when :comment
      "Leave a Comment..."
    when :question
      "Ask a Question..."
    when :answer
      
    when :attached_file
      "Comment on file..."
    when :embedded_snippet
      "Comment on video..."
    when :link
      "Comment on link..."
    when :suggested_action
      "Suggest an action..."
    else
      ""
    end
  end
  
  # This method allows you to get the subset of direct descendents of this_contribution_id from the complete thread of root_contribution_and_descendents
  #  root_contribution in this case is a TopLevelContribution node, and the whole thing has already been loaded by the controller,
  #  so we don't want to poll the database for each subset when we've already loaded the entire set once.
  def display_direct_descendant_subset(contribution_descendants, this_contribution_id)
    out = ""
    return out unless contribution_descendants
    contribution_descendants.select{ |c| c.parent_id == this_contribution_id }.sort_by{ |c| c.created_at }.each do |contribution|
      out += render(:partial => "conversations/contributions/threaded_contribution_template", :locals => { :contribution => contribution })
    end
    raw(out)
  end

  def conversation_node_path(contribution)
    conversation_path(contribution.conversation) + "#node-#{contribution.id}"
  end

  def filter_title(filter, suffix = nil)
    case filter.to_sym
    when :active
      title = "Most Active"
    when :popular
      title = "Most Popular"
    when :recent
      title = "Newest"
    else
      title = "Filtered"
    end

    if suffix then title += suffix end

    title
  end

  def filter_description(filter)
    case filter.to_sym
    when :active
      "These are conversations that are inspiring people to join in."
    when :popular
      "These are the conversations that are sparking interest."
    when :recent
      "These are the conversations that are just getting started."
    else
      "These are the conversations that match your filter."
    end
  end

  def rating_buttons(contribution, ratings_hash)
    out = []
    RatingGroup.rating_descriptors.each do |id, title|
      out << link_to( "#{title} <span>#{ratings_hash[contribution.id][title][:total]}</span>".html_safe, conversation_contribution_toggle_rating_path(:contribution_id => contribution, :rating_descriptor_title => title), :remote => true, :method => :post, :id => "contribution-#{contribution.id}-rating-#{title}", :class => "rating-button #{'active' if ratings_hash[contribution.id][title][:person]}" )
    end
    raw(out.join(' '))
  end
end
