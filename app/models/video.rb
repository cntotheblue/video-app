class Video < ActiveRecord::Base
	has_attachment :content_type => :video, 
                 :storage => :file_system, 
                 :max_size => 300.megabytes


  #acts as state machine plugin
  acts_as_state_machine :initial => :pending
  state :pending
  state :converting
  state :converted, :enter => :set_new_filename
  state :error

  event :convert do
    transitions :from => :pending, :to => :converting
  end

  event :converted do
    transitions :from => :converting, :to => :converted
  end

  event :failure do
    transitions :from => :converting, :to => :error
  end
  

  # This method is called from the controller and takes care of the converting
  def convert
    self.convert!
    success = system(convert_command)
    #logger.debug 'Returned: ' + success.to_s
    if success && $?.exitstatus == 0
      self.converted!
    else
      self.failure!
    end
  end

  protected
  
  def convert_command
		
		#construct new file extension
    flv =  "." + id.to_s + ".flv"

		#build the command to execute ffmpeg
    command = <<-end_command
     ffmpeg -i #{ RAILS_ROOT + '/public' + public_filename }  -ar 22050 -ab 32 -acodec mp3 -s 480x360 -vcodec flv -r 25 -qscale 8 -f flv -y #{ RAILS_ROOT + '/public' + public_filename + flv }
      
    end_command
    
    logger.debug "Converting video...command: " + command
    command
  end

  # This updates the stored filename with the new flash video file
  def set_new_filename
    update_attribute(:filename, "#{filename}.#{id}.flv")
    update_attribute(:content_type, "application/x-flash-video")
  end


end