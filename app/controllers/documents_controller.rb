class DocumentsController < ApplicationController
  def index
    @available_years = Document.available_years
    @year = params[:year] if params[:year] && @available_years.include?(params[:year])
    if @year
      @available_months = Document.available_months(@year)
    end
    @month = params[:month] if params[:month] && @available_months.include?(params[:month])
    
    @documents = Document.order(:timestamp)
    @documents = @documents.where(["year(timestamp) = ?", @year]) if @year
    @documents = @documents.where(["month(timestamp) = ?", @month]) if @month
    @documents = @documents.paginate(:page => params[:page])
  end

  def show

  end
  
end
