shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;
uniform float uSceneMaxDist = 10000000;
uniform sampler2D depth_texture : hint_depth_texture;

void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

struct Ray{
	vec3 origin;
	vec3 dir;
};

struct RaytraceResult{
	vec3 colour;
	bool hit;
	vec3 rayOrigin;
	float rayDist;
};

void plane_intersection(vec3 normal, float dist, Ray ray, inout RaytraceResult result) {
	float rDot = dot(normal, ray.dir);

	float t = -(dot(normal, ray.origin) + dist) / rDot;
	if (t > 0.0 && t < result.rayDist) {
		result.rayDist = t;
		result.hit = true;

		vec3 intersect = ray.origin + t * ray.dir;

		// Example checkerboard colouring
		if (mod(floor(intersect.x/10.0) + floor(intersect.z/10.0), 2) < 1.0) {
			result.colour = vec3(0,1,0);
		} else {
			result.colour = vec3(0,0,1);
		}
	}
}


void process_distance_plane(float dist, Ray ray, inout RaytraceResult result, int index, vec3 anchor, vec3 dimensions){
	if (dist <= 0.0 || dist >= result.rayDist){
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

	result.rayDist = dist;
	result.hit = true;
	result.colour = vec3(0,0,1);
}


void box_intersection(vec3 anchor, vec3 dimensions, Ray ray, inout RaytraceResult result){
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
	process_distance_plane(-planeXDist, ray, result, 0, anchor, dimensions);
	process_distance_plane(-planeYDist, ray, result, 1, anchor, dimensions);
	process_distance_plane(-planeZDist, ray, result, 2, anchor, dimensions);
}


void sphere_intersection(vec3 center, float radius, Ray ray, inout RaytraceResult result) {
	vec3 oc = ray.origin - center;
	float a = dot(ray.dir, ray.dir); // usually 1 if normalized
	float b = 2.0 * dot(oc, ray.dir);
	float c = dot(oc, oc) - radius * radius;
	float discriminant = b*b - 4.0*a*c;

	if (discriminant < 0.0) return; // no hit

	float t = 0.5 * (-b - sqrt(discriminant)) / a; // nearest root
	if (t > 0.0 && t < result.rayDist) {
		result.rayDist = t;
		result.hit = true;
		result.colour = vec3(1,0,0);
	}
}

RaytraceResult raytrace_scene(Ray ray, float maxDepth){
	RaytraceResult ray_result;
	ray_result.rayDist = maxDepth;
	//sphere_intersection(vec3(10, 0, 0), 10, ray, ray_result);
	//plane_intersection(vec3(0, 1, 0), 5, ray, ray_result);
	box_intersection(vec3(0, 0, 0), vec3(10, 10, 5), ray, ray_result);
	return ray_result;
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

	RaytraceResult res = raytrace_scene(ray, min(linear_depth, uSceneMaxDist));

	if (res.hit){
		ALBEDO = res.colour;
		ALPHA = 1.0;
	}
	else{
		ALPHA = 0.0;
	}
}
