class UsersController < ApplicationController
  before_filter :find_user,:only=>[:edit,:show,:update,:followers,:following]
  before_filter :signed_in_user, only: [:edit, :update,:index, :destroy,:followers,:following]
  before_filter :correct_user,   only: [:edit, :update]
  before_filter :admin_user,     only: :destroy

  def new
    @user = User.new
  end


  def create
    @user = User.new(params[:user])

    if @user.save
      @user.send_signup_confirmation
      flash[:success] = "We have sent a confirmation letter to you. Check your email to complete registration."
      redirect_to root_path unless Rails.env.test?

      if Rails.env.test?#для тестов мы хоть и отсылаем e-mail для подвтерждения регистрации, но после этого всё равно пускаем юзера (singin user)
        sign_in @user
        redirect_to @user
      end
    else
      render 'new'
    end
  end

  def index
    @users=User.paginate(page: params[:page])
  end

  def show
    @microposts = @user.microposts.paginate(page: params[:page])
  end


  def edit
  end

  def update
    $debug_info=@user
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated"
      sign_in @user
      redirect_to @user
    else
      render 'edit'
    end
  end


  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User destroyed."
    redirect_to users_url
  end

  def following
    @title = "Following"
    @users = @user.followed_users.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "Followers"
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  def activate
    $debug_info=params
    @user = User.where(id: params[:id], signup_confirm_token: params[:token], active: false).first
    if @user
      if @user.signup_confirm_sent_at > 7.days.ago
        @user.update_attributes(active: true)
        @user.clear_field(:signup_confirm_token)
        flash[:success] = "Your account was activated. You can sign in now."
        redirect_to signin_path
       else
        redirect_to root_path, notice: "Activation was expired"
      end
    else
      redirect_to root_path
    end
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

  #если юзер хочет отредактировать чужие данные, отправляем его на домашнюю страницу сайта
  def correct_user
    redirect_to(root_path) unless current_user?(@user)
  end

  #при попытке удаления юзеров проверяем, админ ли это делает. Если нет, перенаправляем.
  def admin_user
    redirect_to(root_path) unless current_user.admin?
  end

end
