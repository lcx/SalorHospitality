# BillGastro -- The innovative Point Of Sales Software for your Restaurant
# Copyright (C) 2011  Michael Franzl <michael@billgastro.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class ArticlesController < ApplicationController

  before_filter :check_permission

  # tested
  def index
    @categories = @current_vendor.categories.order('position ASC')
    @scopes = ['active','waiterpad']
    respond_to do |wants|
      wants.html
      wants.js {
        send_data @current_vendor.cache, :content_type => 'text/javascript', :disposition => 'inline'
      }
    end
  end

  # tested
  def active
    @categories = Category.accessible_by(@current_user).active
  end

  # tested
  def waiterpad
    @categories = Category.accessible_by(@current_user).active
  end

  # tested
  def update_cache
    @categories = @current_vendor.categories.order('position ASC')
    @scopes = ['menucard','waiterpad']
    @current_vendor.update_attribute :cache, render_to_string('articles/index.js')
    flash[:notice] = t('articles.cache_successfully_updated')
    redirect_to orders_path
  end

  # tested
  def listall
    @articles = Article.accessible_by(@current_user).existing.order('name, description, price')
  end

  # tested
  def new
    @article = Article.new
    @categories = @current_vendor.categories
  end

  # tested
  def create
    @article = Article.new(params[:article])
    if @article.save
      @article.company = @current_company
      @article.vendor = @current_vendor
      @article.save
      redirect_to articles_path
      flash[:notice] = t('articles.create.success')
    else
      @categories = @current_vendor.categories
      flash[:error] = t('articles.create.failure')
      render :new
    end
  end

  # tested
  def edit
    @article = @permitted_model
    @categories = @current_vendor.categories
    session[:return_to] = /.*?\/\/.*?(\/.*)/.match(request.referer)[1] if request.referer # manually tested
    render :new
  end

  # tested
  def update
    @categories = @current_vendor.categories
    @article = @permitted_model
    @article.update_attributes params[:article]

    if @article.save
      flash[:notice] = t('articles.update.success')
      if session[:return_to]
        redirect_to session[:return_to]
        session[:return_to] = nil
      else
        redirect_to orders_path
      end
    else
      flash[:error] = t('articles.update.failure')
      render :new
    end
  end

  # tested
  def destroy
    @article = @permitted_model
    @article.hide
    flash[:notice] = t('articles.destroy.success')
    redirect_to articles_path
  end

  def find
    if params['articles_search_text'].strip.length > 2
      search_terms = params['articles_search_text'].split.collect { |word| "%#{ word.downcase }%" }
      conditions = 'hidden = false AND '
      conditions += (["(LOWER(name) LIKE ?)"] * search_terms.size).join(' AND ')
      @found_articles = Article.scopied.find( :all, :conditions => [ conditions, *search_terms.flatten ], :order => 'name', :limit => 5 )
      #render :partial => 'find', :layout => false
    else
      render :nothing => true
    end
  end

  def change_scope
    @categories = Category.scopied.find(:all, :order => 'position')
    @article = Article.scopied.find(/([0-9]*)$/.match(params[:id])[1])

    @drag_from = /[^_]*/.match(params[:id])[0]
    if params[:scope] == 'remove'
      @article.update_attribute @drag_from.to_sym, false
      render :nothing => true
    elsif @drag_from == params[:scope]
      render :nothing => true
    else
      @drag_to = params[:scope]
      @article.update_attribute @drag_to.to_sym, true
    end
  end

  def sort
    params['article'].each do |id|
      a = Article.scopied.find_by_id id
      a.position = params['article'].index(a.id.to_s) + 1
      a.save
    end
    render :nothing => true
  end

  def sort_index
    @categories = Category.scopied.all
  end

end
