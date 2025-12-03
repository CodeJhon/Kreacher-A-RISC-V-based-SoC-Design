# 设置项目名称和路径
set project_name "kreacher_sim"
set project_dir "./kreacher_sim_project"

# 创建项目（如果存在则先删除）
if {[file exists $project_dir]} {
    file delete -force $project_dir
}
create_project $project_name $project_dir -part xc7a35tcpg236-1 -force

# 收集 RTL 文件
set rtl_files [concat \
    [glob -nocomplain ../vlsi_processor_design_project/Core/*.v] \
    [glob -nocomplain ../vlsi_processor_design_project/Core/*/*.v] \
    [glob -nocomplain ../vlsi_processor_design_project/Memory/src/*.v] \
    [glob -nocomplain ../vlsi_processor_design_project/Kreacher_top/src/*.v] \
]

# 收集测试文件
set tb_files [glob ../vlsi_processor_design_project/Kreacher_top/tb/*.sv]

# 添加 RTL 文件到设计源
if {[llength $rtl_files] > 0} {
    add_files -fileset sources_1 $rtl_files
    puts "Added [llength $rtl_files] RTL files"
} else {
    puts "Warning: No RTL files found!"
}

# 添加测试文件到仿真源
if {[llength $tb_files] > 0} {
    add_files -fileset sim_1 $tb_files
    puts "Added [llength $tb_files] testbench files"
} else {
    puts "Warning: No testbench files found!"
}

# 设置 include 目录（对设计源和仿真源都设置）
set_property include_dirs [list ../vlsi_processor_design_project/Core/include] [current_fileset]
set_property include_dirs [list ../vlsi_processor_design_project/Core/include] [get_filesets sim_1]

# 设置仿真顶层模块
set_property top tb_kreacher_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# 更新编译顺序
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 设置仿真选项
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

# 启动仿真
puts "Launching simulation..."
launch_simulation

# 运行仿真
run all

# 关闭仿真
close_sim

# 关闭项目
close_project

puts "Simulation completed successfully!"