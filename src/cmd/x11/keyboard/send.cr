# Send, Keys
class Cmd::X11::Keyboard::Send < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.display.pause do # to prevent hotkey from triggering other hotkey or itself
			thread.runner.display.x_do.clear_active_modifiers thread.runner.display.x_do.active_modifiers
			thread.parse_key_combinations_to_charcodemap(args[0]) do |key_map, pressed, mouse_button|
				if mouse_button
					if pressed
						thread.runner.display.x_do.mouse_down mouse_button
					else
						thread.runner.display.x_do.mouse_up mouse_button
					end
				else
					thread.runner.display.x_do.keys_raw key_map, pressed: pressed, delay: 0
				end
			end
		end
	end
end