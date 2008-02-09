class GroupsController < ApplicationController
  
  def editor
    if request.post?
      associations = params.select { |(key,value)| key =~ /^membership/ }
      Membership.redefine_membership_associations_with normalize_associations(associations)
    end
    
    @groups    = Group.find :all
    @employees = Employee.find(:all, :include => :groups).sort_by { |e| e.name[/\s*\S+$/].downcase }
  end
  
  def extension_manager
    @groups = Group.find :all# , :order => ''
    @employees = Employee.find :all
    
  end
  
  private
  
  def normalize_associations(associations)
    associations.map do |(key,value)|
      key.match(/^membership_(\d+)_(\d+)$/).captures.map &:to_i
    end
  end
  
end

# Collapse this to clean everything up.
class GroupsController < ApplicationController
  
  # def index
  #   @groups = Group.find(:all)
  # 
  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.xml  { render :xml => @groups }
  #   end
  # end
  # 
  # def show
  #   @group = Group.find(params[:id])
  # 
  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.xml  { render :xml => @group }
  #   end
  # end
  # 
  # def new
  #   @group = Group.new
  # 
  #   respond_to do |format|
  #     format.html
  #     format.xml  { render :xml => @group }
  #   end
  # end
  # 
  # def edit
  #   @group = Group.find(params[:id])
  # end
  # 
  # def create
  #   @group = Group.new(params[:group])
  # 
  #   respond_to do |format|
  #     if @group.save
  #       flash[:notice] = 'Group was successfully created.'
  #       format.html { redirect_to(@group) }
  #       format.xml  { render :xml => @group, :status => :created, :location => @group }
  #     else
  #       format.html { render :action => "new" }
  #       format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # def update
  #   @group = Group.find(params[:id])
  # 
  #   respond_to do |format|
  #     if @group.update_attributes(params[:group])
  #       flash[:notice] = 'Group was successfully updated.'
  #       format.html { redirect_to(@group) }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render :action => "edit" }
  #       format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # def destroy
  #   @group = Group.find(params[:id])
  #   @group.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(groups_url) }
  #     format.xml  { head :ok }
  #   end
  # end
end
