class_name ImplicidSurface extends Node3D

@onready var control = $Control
@onready var slider_pos_x: HSlider = $Control/VBoxContainer/HBPosX/VBoxContainer/slider_pos_x
@onready var slider_pos_y: HSlider = $Control/VBoxContainer/HBPosY/VBoxContainer/slider_pos_y
@onready var slider_pos_z: HSlider = $Control/VBoxContainer/HBPosZ/VBoxContainer/slider_pos_z
@onready var slider_radius = $Control/VBoxContainer/HBRadius/VBoxContainer/slider_radius
@onready var function_select: OptionButton = $Control/VBoxContainer/HBFuncSelect/VBoxContainer/function_select
@onready var collision_shape = $Area3D/CollisionShape3D
@onready var surface_mesh: MeshInstance3D = $surface_mesh
@onready var render_manager: RenderManager = get_tree().root.get_node("MainScene/RenderManager")
@onready var selection_manager: SelectionManager = get_tree().root.get_node("MainScene/SelectionManager")
@export var is_negative := false
@export var voxel_grid: VoxelGrid
enum FunctionType {SPHERE, TORUS}
@export var function_type := FunctionType.SPHERE
var function_map := {
	FunctionType.SPHERE: _sphere,
	#FunctionType.ELLIPSOID: _ellipsoid,
	FunctionType.TORUS: _torus, 
}
var r := 2.0
var iso := 0.0
var mouse_over := false
var is_selecting := false
var ignore_mouse:= false

func _ready():
	slider_radius.value = r
	slider_pos_x.value = position.x
	slider_pos_y.value = position.y
	slider_pos_z.value = position.z
	slider_pos_x.max_value = voxel_grid.position.x + voxel_grid.resolution
	slider_pos_y.max_value = voxel_grid.position.y + voxel_grid.resolution
	slider_pos_z.max_value = voxel_grid.position.z + voxel_grid.resolution
	slider_pos_x.min_value = voxel_grid.position.x
	slider_pos_y.min_value = voxel_grid.position.y
	slider_pos_z.min_value = voxel_grid.position.z
	function_select.selected = function_type
	#surface_mesh.position -= position
	update_selection_mesh()
	update_collision_shape()

#func _process(delta):
	##visual feedback for surface selection
	#if is_selecting && mouse_over:
		#selection_mouse_enter.emit()
		#selection_manager.hover_over = self

func _sphere(x: int, y: int, z: int):
	return pow((position.x - x),2) + pow((position.y - y),2) + pow((position.z - z),2) - r*r;

#func _heart(x: int, y: int, z: int, r: float):
	#return pow((x*x + y*y + z*z - 1),3) - (1/5*x*x + y*y) * pow(z,3)

func _ellipsoid(x: int, y: int, z: int):
	return x*x - y*y - z*z + 1

func _torus(x:int, y:int, z:int):
	return pow((7.0/2.0 - sqrt(pow((position.x - x),2) + pow((position.y - y),2))),2) + pow((position.z - z),2) - r*r

func _on_area_3d_mouse_entered():
	if ignore_mouse:
		return
	selection_manager.set_hover_over(self)

func _on_area_3d_mouse_exited():
	if ignore_mouse:
		return
	selection_manager.reset_hover()

func _on_slider_iso_value_changed(value):
	iso = value
	render_manager.generate_mesh()

func _on_slider_radius_value_changed(value):
	r = value
	render_manager.generate_main_mesh()
	surface_mesh.mesh = render_manager.generate_selection_mesh(self)

func _on_slider_pos_x_value_changed(value):
	if value == round(position.x):
		return
	position.x = value
	render_manager.generate_main_mesh()

func _on_slider_pos_y_value_changed(value):
	if value == round(position.y):
		return
	position.y = value
	render_manager.generate_main_mesh()

func _on_slider_pos_z_value_changed(value):
	if value == round(position.z):
		return
	position.z = value
	render_manager.generate_main_mesh()

func _on_slider_radius_drag_ended(value_changed):
	update_selection_mesh()
	update_collision_shape()

func _on_slider_pos_x_drag_ended(value_changed):
	update_selection_mesh()


func _on_slider_pos_y_drag_ended(value_changed):
	update_selection_mesh()


func _on_slider_pos_z_drag_ended(value_changed):
	update_selection_mesh()

func _on_button_pressed() -> void:
	var half_res:int = voxel_grid.resolution / 2
	position = Vector3(half_res, half_res, half_res)
	render_manager.generate_main_mesh()

func _on_cb_negative_toggled(toggled_on: bool) -> void:
	var index = render_manager.surfaces.find(self)
	is_negative = !is_negative
	if is_negative:
		render_manager.positive_surfaces.erase(index)
		render_manager.negative_surfaces.append(index)
	else:
		render_manager.positive_surfaces.append(index)
		render_manager.negative_surfaces.erase(index)
	
	render_manager.generate_main_mesh()

func _on_option_button_item_selected(index: int) -> void:
	function_type = index
	render_manager.generate_main_mesh()
	surface_mesh.mesh = render_manager.generate_selection_mesh(self)

func _disable_collision():
	collision_shape.disabled = true

func _enable_collision():
	collision_shape.disabled = false
	
func update_selection_mesh():
	surface_mesh.mesh = render_manager.generate_selection_mesh(self)

func update_collision_shape():
	var aabb = surface_mesh.get_aabb()
	var box_shape := BoxShape3D.new()
	box_shape.size = aabb.size / 5.0 #for some reason the aabb is 5 times bigger than the mesh
	collision_shape.shape = box_shape

func on_show_negatives():
	ignore_mouse = true
	_disable_collision()
	on_hover()

func on_hide_negatives():
	ignore_mouse = false
	_enable_collision()
	on_unhover()

func evaluate(x: int, y: int, z: int):
	return function_map[function_type].call(x, y, z)

func on_hover():
	surface_mesh.show()

func on_unhover():
	surface_mesh.hide()

func hide_ui():
	control.hide()

func show_ui():
	control.show()
