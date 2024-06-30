shader_type spatial;

render_mode world_vertex_coords;

void vertex() {
	VERTEX.y += cos(VERTEX.x * 4.0) * sin(VERTEX.z * 4.0) * 18.0;
}

void fragment() {
	NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	
	ALBEDO = vec3(0.23529411764705882, 0.3686274509803922, 0.5450980392156862);
	ROUGHNESS = 0.123;
	
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
