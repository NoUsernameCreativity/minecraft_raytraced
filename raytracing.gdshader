shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;
uniform float uSceneMaxDist = 10000000;
uniform sampler2D depth_texture : hint_depth_texture;

uniform vec3 u_viewBoxAnchor = vec3(0, 0, 0);
uniform vec3 u_viewBoxDim = vec3(20, 20, 20);

/*
Vertex shader, keeps the mesh vertices over the screen
*/
void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}


/*
Ray struct, for storing a ray.
*/
struct Ray{
	vec3 origin;
	vec3 dir;
	float dist;
	bool hit;
	vec3 colour;
};


void plane_intersection(vec3 normal, float dist, inout Ray ray) {
	float rDot = dot(normal, ray.dir);

	float t = -(dot(normal, ray.origin) + dist) / rDot;
	if (t > 0.0 && t < ray.dist) {
		ray.dist = t;
		ray.hit = true;

		vec3 intersect = ray.origin + t * ray.dir;

		// Example checkerboard colouring
		if (mod(floor(intersect.x/10.0) + floor(intersect.z/10.0), 2) < 1.0) {
			ray.colour = vec3(0,1,0);
		} else {
			ray.colour = vec3(0,0,1);
		}
	}
}


void process_distance_plane(float dist, inout Ray ray, int index, vec3 anchor, vec3 dimensions){
	if (dist <= 0.0 || dist >= ray.dist){
		return;
	}
	vec3 intersection = ray.origin + dist * ray.dir - anchor;
	if ((intersection.x < 0.0 || intersection.x > dimensions.x) && index != 0){
		return;
	}
	if ((intersection.y < 0.0 || intersection.y > dimensions.y) && index != 1){
		return;
	}
	if ((intersection.z < 0.0 || intersection.z > dimensions.z) && index != 2){
		return;
	}

	ray.dist = dist;
	ray.hit = true;
	ray.colour = vec3(0,0,1);
}


/*
Box intersection function.
*/
void box_intersection(vec3 anchor, vec3 dimensions, inout Ray ray){
	// we only need to check the plane which is at the anchor if we are to the left of the anchor
	float planeXDist;
	float planeYDist;
	float planeZDist;
	if (ray.origin.x <= anchor.x){
		planeXDist = (ray.origin.x - anchor.x) / ray.dir.x;
	}
	else{
		planeXDist = (ray.origin.x - anchor.x - dimensions.x) / ray.dir.x;
	}
	if (ray.origin.y <= anchor.y){
		planeYDist = (ray.origin.y - anchor.y) / ray.dir.y;
	}
	else{
		planeYDist = (ray.origin.y - anchor.y - dimensions.y) / ray.dir.y;
	}
	if (ray.origin.z <= anchor.z){
		planeZDist = (ray.origin.z - anchor.z) / ray.dir.z;
	}
	else{
		planeZDist = (ray.origin.z - anchor.z - dimensions.z) / ray.dir.z;
	}
	process_distance_plane(-planeXDist, ray, 0, anchor, dimensions);
	process_distance_plane(-planeYDist, ray, 1, anchor, dimensions);
	process_distance_plane(-planeZDist, ray, 2, anchor, dimensions);
}

bool insideSceneBox(vec3 pos){
	vec3 dc = pos - u_viewBoxAnchor;
	if ((dc.x < 0.0 || dc.x > u_viewBoxDim.x)){
		return false;
	}
	if ((dc.y < 0.0 || dc.y > u_viewBoxDim.y)){
		return false;
	}
	if ((dc.z < 0.0 || dc.z > u_viewBoxDim.z)){
		return false;
	}
	return true;
}

/*
This code jumps the ray to the scene box, if the ray is not inside the scene box already.
Returns false if the player is not inside the box or if the ray misses the box.
*/
bool raytrace_to_scene_box(inout Ray ray){
	if (insideSceneBox(ray.origin)){
		return true;
	}

	Ray temp_ray;
	temp_ray.origin = ray.origin;
	temp_ray.dir = ray.dir;
	temp_ray.dist = ray.dist;
	box_intersection(u_viewBoxAnchor, u_viewBoxDim, temp_ray);
	if (temp_ray.hit){
		ray = temp_ray;
		return true;
	}
	return false;
}




/*
Main function to raytrace the scene. Mixes together intersections
*/
Ray raytrace_scene(Ray ray, float maxDepth){
	Ray ray_result;
	ray_result.origin = ray.origin;
	ray_result.dir = ray.dir;
	ray_result.dist = maxDepth;

	if (!raytrace_to_scene_box(ray_result)){
		return ray_result;
	}

	Ray new_ray;
	new_ray.origin = ray_result.origin;
	new_ray.hit = false;
	new_ray.dir = ray.dir;
	new_ray.dist = maxDepth;

	plane_intersection(vec3(0, 1, 0), 10, new_ray);
	box_intersection(vec3(20, 0, 0), vec3(10, 10, 5), new_ray);
	return new_ray;
}

void fragment() {
	vec2 uv = SCREEN_UV * 2.0 - 1.0; // NDC in [-1,1]
	vec4 clipPos = vec4(uv, 1.0, 1.0);

	// Step 1: go to view space
	vec4 viewPos = INV_PROJECTION_MATRIX * clipPos;
	viewPos /= viewPos.w; // perspective divide

	// Step 2: go to world space
	vec4 worldPos = INV_VIEW_MATRIX * viewPos;

	// Step 3: ray origin and direction
	vec3 ray_origin = (INV_VIEW_MATRIX[3]).xyz; // camera position
	vec3 ray_dir = normalize(worldPos.xyz - ray_origin);

	// get depth
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	// actually march ray


	Ray ray;
	ray.dir = ray_dir;
	ray.origin = ray_origin;

	Ray res = raytrace_scene(ray, min(linear_depth, uSceneMaxDist));
	if (res.hit){
		ALBEDO = res.colour;
		ALPHA = 1.0;
	}
	else{
		ALPHA = 0.0;
	}
}
