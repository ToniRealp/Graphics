#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 128) out;

out vec4 face_color;

uniform mat4 projection;
uniform mat4 view;

uniform float random_values[8];

float h = 2.0f;
float delta = 0.5f;

vec4 hexagon_color = vec4(0.2, 0.4, 0.6, 1.0);
vec4 quad_color = vec4(0.114, 0.161, 0.318, 1.0);

void emit_vertex(vec2 vertex)
{
	gl_Position = projection * view * vec4(vertex, 0, 1.0);
	EmitVertex();
}

void emit_vertex(vec3 vertex)
{
	gl_Position = projection * view * vec4(vertex, 1.0);
	EmitVertex();
}

vec3 midpoint(vec2 p1, vec2 p2)
{
	return vec3((p1 + p2) / 2.0f, 0);
}

vec3 emit_triangle(vec2 p1, vec2 p2)
{
	vec3 vertex = midpoint(p1, p2) + vec3(0.0, 0.0, -1.0) * delta;
	
	face_color = quad_color;
	emit_vertex(p2);
	emit_vertex(vertex);
	emit_vertex(p1);
	EndPrimitive();

	return vertex;
}

void emit_hexagon(vec3 v1, vec2 v2, vec3 v3, vec2 v4, vec3 v5, vec3 v6)
{
	face_color = hexagon_color;
	
	emit_vertex(v1);
	emit_vertex(v2);
	emit_vertex(v3);
	emit_vertex(v4);
	emit_vertex(v5);
	emit_vertex(v6);

	EndPrimitive();
}

void emit_quad(vec3 v1, vec3 v2, vec3 v3, vec3 v4)
{
	face_color = quad_color;

	emit_vertex(v1);
	emit_vertex(v2);
	emit_vertex(v3);
	emit_vertex(v4);

	EndPrimitive();
}


void main()
{
	vec2 center = gl_in[0].gl_Position.xy;

	// -- VERTICES -------------------------------------------------------------------------
	vec2 vertices[8];
	vertices[0] = vec2(center.x - 2, center.y + 2);
	vertices[1] = vec2(center.x, center.y + 2);
	vertices[2] = vec2(center.x + 2, center.y + 2);
	vertices[3] = vec2(center.x + 3, center.y);
	vertices[4] = vec2(center.x + 2, center.y - 2);
	vertices[5] = vec2(center.x, center.y - 2);
	vertices[6] = vec2(center.x - 2, center.y - 2);
	vertices[7] = vec2(center.x - 3, center.y);

	// -- MID POINTS -------------------------------------------------------------------------
	vec2 midpoints[8];
	for (int i = 0; i < 8; i++)
	{
		// Randomize position.
		vertices[i].x += random_values[i];

		// Compute midpoint.
		midpoints[i] = (center + vertices[i]) / 2;
	}

	// -- LINES -------------------------------------------------------------------------
	float slopes[8];
	float intercepts[8];

	for (int i = 0; i < 8; i++)
	{
		// Perpendicular vector.
		vec2 director = vertices[i] - center;
		director = vec2(director.y, -1 * director.x);

		// Singularity handling.
		if (director.x == 0) {
			director.x = 0.00001;
		}

		// Compute slopes and intercepts.
		slopes[i] = director.y / director.x;
		intercepts[i] = midpoints[i].y - slopes[i] * midpoints[i].x;
	}

	// -- INTERSECTIONS -------------------------------------------------------------------------
	// y1 = ax + c; y2 = bx + d
	// x = (d - c) / (a - b)
	vec2 intersections[8];
	for (int i = 0; i < 8; i++)
	{
		intersections[i].x = (intercepts[int(mod(i + 1, 8))] - intercepts[i]) / (slopes[i] - slopes[int(mod(i + 1, 8))]);
		intersections[i].y = slopes[i] * intersections[i].x + intercepts[i];
	}

	// -- QUAD -------------------------------------------------------------------------
	vec3 direction = vec3(0.0, 0.0, -1.0);

	vec3 quad_center = vec3(center, 0.0) + direction * h;
	vec3 down_right = quad_center + vec3(1.0, -1.0, 0.0) * delta;
	vec3 down_left = quad_center + vec3(-1.0, -1.0, 0.0) * delta;
	vec3 up_right = quad_center + vec3(1.0, 1.0, 0.0) * delta;
	vec3 up_left = quad_center + vec3(-1.0, 1.0, 0.0) * delta;

	emit_quad(up_right, down_right, up_left, down_left);

	// -- FACES -------------------------------------------------------------------------
	vec3 triangle_up_right = emit_triangle(intersections[1], intersections[2]);
	vec3 triangle_down_right = emit_triangle(intersections[3], intersections[4]);
	vec3 triangle_down_left = emit_triangle(intersections[5], intersections[6]);
	vec3 triangle_up_left = emit_triangle(intersections[7], intersections[0]);

	emit_hexagon(triangle_up_left, intersections[0], up_left, intersections[1], up_right, triangle_up_right);
	emit_hexagon(triangle_up_right, intersections[2], up_right, intersections[3], down_right, triangle_down_right);
	emit_hexagon(triangle_down_right, intersections[4], down_right, intersections[5], down_left, triangle_down_left);
	emit_hexagon(triangle_down_left, intersections[6], down_left, intersections[7], up_left, triangle_up_left);
}