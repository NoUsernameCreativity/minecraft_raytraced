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
	sphere_intersection(vec3(10, 0, 0), 10, ray, ray_result);
	plane_intersection(vec3(0, 1, 0), 5, ray, ray_result);
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
