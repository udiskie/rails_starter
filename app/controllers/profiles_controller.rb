class ProfilesController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    if Current.user.update(params.permit(:name, :email_address))
      redirect_to dashboard_path, notice: "Profile updated."
    else
      @user = Current.user
      render :edit, status: :unprocessable_entity
    end
  end
end
