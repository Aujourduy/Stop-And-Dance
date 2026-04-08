class Admin::SettingsController < Admin::ApplicationController
  def edit
    @setting = Setting.instance
  end

  def update
    @setting = Setting.instance

    if @setting.update(setting_params)
      redirect_to edit_admin_settings_path, notice: "Paramètres mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:claude_global_instructions, :openrouter_default_model, :acronymes_preserves)
  end
end
