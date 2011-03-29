class HomepageController < ApplicationController
  def show
    @most_visited_conversations = Conversation.get_top_visited(3)

    @conversations = Conversation.order("created_at DESC").paginate(:page => params[:page], :per_page => 12)

    @main_article = Article.homepage_main_article.first
    @sub_articles = Article.homepage_sub_articles.limit(3)
    @regions = Region.all

    @recent_items = TopItem.newest_items(3).with_items_and_associations.collect(&:item)
  end
end
