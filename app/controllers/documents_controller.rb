class DocumentsController < ApplicationController
  def index
    @available_years = Document.available_years
    @year = params[:year].to_i if params[:year] && @available_years.include?(params[:year].to_i)
    if @year
      @available_months = Document.available_months(@year)
    end
    @month = params[:month].to_i if params[:month] && @available_months.include?(params[:month].to_i)
    
    @documents = Document.order(:timestamp)
    @documents = @documents.where(["year(timestamp) = ?", @year]) if @year
    @documents = @documents.where(["month(timestamp) = ?", @month]) if @month
    @documents = @documents.paginate(:page => params[:page])
  end

  def show
    @document = Document.find(params[:id])
  end
  
end
