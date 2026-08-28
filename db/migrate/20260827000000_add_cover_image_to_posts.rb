class AddCoverImageToPosts < ActiveRecord::Migration[8.1]
  def change
    # ActiveStorage tables are already created by rails active_storage:install
    # This migration just adds the attachment association to Post model
    # No schema changes needed - ActiveStorage uses active_storage_attachments table
  end
end
