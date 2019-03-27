#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 96) out;

out vec4 face_color;

uniform mat4 projection;
uniform mat4 view;

float h = 1.0f;
float delta = 0.25f;

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

void emit_hexagon(vec3 v1, vec3 v2, vec3 v3, vec4 color)
{
	vec3 v12 = v2 - v1;
	vec3 v23 = v3 - v2;
	vec3 v31 = v1 - v3;

	vec3 vf1 = v1 + v12 * delta;
	vec3 vf2 = v1 + v12 * (1 - delta);
	vec3 vf3 = v2 + v23 * delta;
	vec3 vf4 = v2 + v23 * (1 - delta);
	vec3 vf5 = v3 + v31 * delta;
	vec3 vf6 = v3 + v31 * (1 - delta);

	create_face(vf1, vf2, vf3, color);
	create_face(vf1, vf3, vf4, color);
	create_face(vf1, vf4, vf5, color);
	create_face(vf1, vf5, vf6, color);
}

void emit_square(vec3 v1, vec3 v2, vec3 v3, vec4 color)
{
	vec3 v12 = (v2 - v1) * delta;
	vec3 v13 = (v3 - v1) * delta;

	vec3 center = v12 * dot(v12, vec3(0.0, 1.0, 0.0));

	vec3 vf1 = v1 + v12;
	vec3 vf2 = v1 + v13;
	vec3 vf3 = (center - vf1) * 2;
	vec3 vf4 = (center - vf2) * 2;

	create_face(vf1, vf2, vf3, color);
	create_face(vf1, vf3, vf4, color);
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

	emit_hexagon(top_vertex, back_right_vertex, back_left_vertex, vec4(1.0, 0.0, 0.0, 1.0));
	emit_hexagon(top_vertex, front_left_vertex, front_right_vertex, vec4(1.0, 0.0, 0.0, 1.0));
	emit_hexagon(top_vertex, back_left_vertex, front_left_vertex, vec4(1.0, 0.0, 0.0, 1.0));
	emit_hexagon(top_vertex, front_right_vertex, back_right_vertex, vec4(1.0, 0.0, 0.0, 1.0));
	emit_hexagon(bot_vertex, back_left_vertex, back_right_vertex, vec4(0.0, 1.0, 0.0, 1.0));
	emit_hexagon(bot_vertex, front_right_vertex, front_left_vertex, vec4(1.0, 0.0, 0.0, 1.0));
	emit_hexagon(bot_vertex, front_left_vertex, back_left_vertex, vec4(1.0, 0.0, 0.0, 1.0));
	emit_hexagon(bot_vertex, back_right_vertex, front_right_vertex, vec4(1.0, 0.0, 0.0, 1.0));

	emit_square(top_vertex, back_right_vertex, back_left_vertex, vec4(0.0, 0.0, 1.0, 1.0));
}