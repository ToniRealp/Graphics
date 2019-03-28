#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 96) out;

out vec4 face_color;

uniform mat4 projection;
uniform mat4 view;

struct Quad
{
	vec3 positions[4];
};

float h = 1.0f;
float delta = 0.25f;

vec4 red = vec4(1.0, 0.0, 0.0, 1.0);

void create_face(vec3 v1, vec3 v2, vec3 v3, vec4 color)
{
	face_color = color;


	gl_Position = projection * view * vec4(v1, 1.0);
	EmitVertex();

	gl_Position = projection * view * vec4(v2, 1.0);
	EmitVertex();

	gl_Position = projection * view * vec4(v3, 1.0);
	EmitVertex();


	EndPrimitive();
}

Quad emit_quad(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5, vec4 color)
{
	Quad quad = Quad(vec3[4](v1 + (v2 - v1) * delta, v1 + (v3 - v1) * delta, v1 + (v4 - v1) * delta, v1 + (v5 - v1) * delta));

	create_face(quad.positions[0], quad.positions[1], quad.positions[2], color);
	create_face(quad.positions[2], quad.positions[3], quad.positions[0], color);

	return quad;
};

void emit_hexagon(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5, vec3 v6, vec4 color)
{
	create_face(v1, v2, v3, color);
	create_face(v1, v3, v4, color);
	create_face(v1, v4, v5, color);
	create_face(v1, v5, v6, color);
}

void main()
{
	vec3 center = gl_in[0].gl_Position.xyz;

	vec3 top_vertex = center + vec3(0.0, 1.0, 0.0) * h;
	vec3 bot_vertex = center + vec3(0.0, -1.0, 0.0) * h;

	vec3 back_left_vertex = center + vec3(-1.0, 0.0, -1.0) * h;
	vec3 back_right_vertex = center + vec3(1.0, 0.0, -1.0) * h;

	vec3 front_left_vertex = center + vec3(-1.0, 0.0, 1.0) * h;
	vec3 front_right_vertex = center + vec3(1.0, 0.0, 1.0) * h;

	Quad quad_top = emit_quad(top_vertex, back_right_vertex, back_left_vertex, front_left_vertex, front_right_vertex, red);
	Quad quad_bot = emit_quad(bot_vertex, front_right_vertex, front_left_vertex, back_left_vertex, back_right_vertex, red);

	Quad quad_front_right = emit_quad(front_right_vertex, back_right_vertex, top_vertex, front_left_vertex, bot_vertex, red);
	Quad quad_front_left = emit_quad(front_left_vertex, front_right_vertex, top_vertex, back_left_vertex, bot_vertex, red);

	Quad quad_back_right = emit_quad(back_right_vertex, back_left_vertex, top_vertex, front_right_vertex, bot_vertex, red);
	Quad quad_back_left = emit_quad(back_left_vertex, front_left_vertex, top_vertex, back_right_vertex, bot_vertex, red);
	
	emit_hexagon(quad_top.positions[2], quad_front_left.positions[1], quad_front_left.positions[0], quad_front_right.positions[2], quad_front_right.positions[1], quad_top.positions[3], red);
	
}