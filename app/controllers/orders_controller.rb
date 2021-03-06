class OrdersController < ApplicationController
  before_action :authenticate_user!, only: [:index, :new, :show, :edit, :update, :destroy, :home]
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
   #     @orders = Order.user_id.where(is_joined: 1 ).page(params[:page]).per(5)
 
   # @orders = Order.all.where(user_id: current_user.id  )

    @orders = Order.currentUserOrders(current_user.id).order("created_at desc").page(params[:page]).per(3)
    @orderJoined = OrdersUser.joinedOrders(current_user.id).order("created_at desc").page(params[:page]).per(3)

    @ordersJoined = []
    @orderJoined.each do |order|
    torder = Order.getOrderDetails(order.order_id)
    tcount = OrdersUser.countJoined(order.order_id)
    #@ordersJoined += torder if torder
     @ordersJoined += torder if torder
    # @ordersJoined += tcount
    end 

  end

  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
    @select_error = ""
  end

  # GET /orders/1/edit
  def edit
  end

  def home
    @myfriendsids=current_user.following_users.map { |e| e.id }
     @orders = Order.where(user_id: current_user.id).order("created_at desc").last(5)
     @activities = PublicActivity::Activity.where(owner_id: @myfriendsids)
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)
    @order.user_id = current_user.id
    @order.status = 0
    if params[:users] != "" || params[:group_users] != ""


      users_arr = "[" + params[:users] + "]"
      users_ids = eval(users_arr)

      group_users_arr = "[" + params[:group_users] + "]"
      group_users_ids = eval(group_users_arr)

      users_ids.push(*group_users_ids)

      respond_to do |format|
        if @order.save
         @order.create_activity :create, owner: current_user
         users_ids.uniq.each do |id|
          orders_user = OrdersUser.new( :order_id => @order.id , :user_id => id , :is_joined => false ).save
          Notification.create(recipient: User.find(id), actor: current_user, action: "invited", notifiable: @order, remove: false)
        end
        format.html { redirect_to @order, notice: 'Order was successfully created.' }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  else
    respond_to do |format|
      @select_error =  " please select at leat 1 friend. "
      format.html { render :new }
      format.json { render json: @select_error, status: :unprocessable_entity }
    end
    # render template: "notifications/new"
  end
end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update("status" => "finished")
         format.html { redirect_to :back }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: 'Order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:image, :for, :from,:avatar)

    end
end
