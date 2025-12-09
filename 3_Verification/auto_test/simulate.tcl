# Set project name and path
set project_name "Vivado_Kreacher"
set project_dir "Vivado_Kreacher_temp"

# Open existing project
open_project $project_dir/$project_name.xpr

# launch simulation
puts "Launching simulation..."
launch_simulation

# run simulation
run all

# close simulation
close_sim

# close project
close_project

puts "Simulation completed successfully!" 